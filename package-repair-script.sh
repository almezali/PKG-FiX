#!/bin/bash

# تعيين الألوان للإخراج
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# تعيين المسارات
WORK_DIR="$HOME/pkg_repair"
LOG_DIR="$WORK_DIR/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# إنشاء المجلدات
mkdir -p "$WORK_DIR" "$LOG_DIR"

# وظيفة لعرض الرسائل
show_message() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/repair_$TIMESTAMP.log"
}

# وظيفة لعرض التقدم
show_progress() {
    echo -ne "${YELLOW}$1${NC}\r"
}

# وظيفة لفحص الحزم
analyze_packages() {
    show_message "بدء تحليل الحزم الفاشلة..."
    
    # إنشاء ملفات للتصنيف
    > "$WORK_DIR/official_repos.txt"
    > "$WORK_DIR/not_in_repos.txt"
    > "$WORK_DIR/conflicts.txt"
    > "$WORK_DIR/aur_packages.txt"
    
    total_pkgs=$(wc -l < ~/pkg_error.log)
    current=0
    
    while read line; do
        ((current++))
        pkg=$(echo "$line" | cut -d':' -f1)
        show_progress "تحليل الحزم: $current من $total_pkgs"
        
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            echo "$pkg" >> "$WORK_DIR/official_repos.txt"
        else
            # تحقق إذا كانت الحزمة موجودة في AUR
            if curl -s "https://aur.archlinux.org/packages/$pkg" | grep -q "Package Details:"; then
                echo "$pkg" >> "$WORK_DIR/aur_packages.txt"
            else
                echo "$pkg" >> "$WORK_DIR/not_in_repos.txt"
            fi
        fi
    done < ~/pkg_error.log
    
    echo -e "\n"
}

# وظيفة لتثبيت الحزم الرسمية
install_official_packages() {
    show_message "محاولة تثبيت الحزم الرسمية..."
    
    total_official=$(wc -l < "$WORK_DIR/official_repos.txt")
    if [ $total_official -eq 0 ]; then
        show_message "${YELLOW}لا توجد حزم رسمية للتثبيت${NC}"
        return
    fi
    
    # تثبيت الحزم في مجموعات من 10
    current=0
    > "$WORK_DIR/successful_installs.txt"
    while read -r pkg; do
        ((current++))
        show_progress "تثبيت الحزم الرسمية: $current من $total_official"
        
        if sudo pacman -S --needed --noconfirm --overwrite "/*" "$pkg" >/dev/null 2>&1; then
            echo "$pkg" >> "$WORK_DIR/successful_installs.txt"
        else
            echo "$pkg" >> "$WORK_DIR/conflicts.txt"
        fi
    done < "$WORK_DIR/official_repos.txt"
    
    echo -e "\n"
}

# وظيفة لإظهار التقرير النهائي
show_report() {
    echo -e "\n${GREEN}=== تقرير التثبيت ===${NC}"
    echo -e "الحزم الرسمية المثبتة بنجاح: ${GREEN}$(wc -l < "$WORK_DIR/successful_installs.txt" 2>/dev/null || echo 0)${NC}"
    echo -e "الحزم التي تحتاج إلى AUR: ${YELLOW}$(wc -l < "$WORK_DIR/aur_packages.txt" 2>/dev/null || echo 0)${NC}"
    echo -e "الحزم غير الموجودة: ${RED}$(wc -l < "$WORK_DIR/not_in_repos.txt" 2>/dev/null || echo 0)${NC}"
    echo -e "الحزم المتعارضة: ${RED}$(wc -l < "$WORK_DIR/conflicts.txt" 2>/dev/null || echo 0)${NC}"
    
    # عرض قائمة الحزم التي تحتاج إلى اهتمام
    if [ -s "$WORK_DIR/aur_packages.txt" ]; then
        echo -e "\n${YELLOW}الحزم التي تحتاج إلى تثبيت من AUR:${NC}"
        cat "$WORK_DIR/aur_packages.txt"
    fi
    
    if [ -s "$WORK_DIR/conflicts.txt" ]; then
        echo -e "\n${RED}الحزم التي واجهت تعارضات:${NC}"
        cat "$WORK_DIR/conflicts.txt"
    fi
    
    echo -e "\n${BLUE}جميع السجلات محفوظة في: $LOG_DIR${NC}"
}

# التنفيذ الرئيسي
show_message "بدء عملية إصلاح الحزم..."
analyze_packages
install_official_packages
show_report

# إنشاء سكربت للتثبيت اليدوي
cat > "$WORK_DIR/manual_install.sh" << 'EOF'
#!/bin/bash
# تثبيت حزم AUR
if [ -f "aur_packages.txt" ]; then
    while read pkg; do
        yay -S --noconfirm "$pkg"
    done < aur_packages.txt
fi
EOF
chmod +x "$WORK_DIR/manual_install.sh"

show_message "تم إنشاء سكربت للتثبيت اليدوي في: $WORK_DIR/manual_install.sh"
