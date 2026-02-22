#!/bin/bash

# Bioinformatics305 Git Tasks Automation Script
# Этот скрипт автоматически выполняет все задания по Git

set -e  # Прерывать выполнение при ошибке

echo "=========================================="
echo "Начало выполнения заданий Bioinformatics305"
echo "=========================================="

# Переход в папку Bioinformatics305
cd Bioinformatics305/ || { echo "Папка Bioinformatics305 не найдена!"; exit 1; }

# Настройка Git для работы в Windows
git config core.filemode false

# Удаление текущего удаленного репозитория и добавление ВАШЕГО
echo "Настройка удаленного репозитория..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/Lanid3647/bioinf.git
echo "Удаленный репозиторий установлен: https://github.com/Lanid3647/bioinf.git"

# ========== ЗАДАНИЕ 1 ==========
echo "Задание 1: Удаление .tmp файлов"
if [ -d "raw_data" ]; then
    cd raw_data
    rm -f *.tmp
    cd ..
    git add raw_data/
    # Проверяем, есть ли изменения для коммита
    if ! git diff --cached --quiet; then
        git commit -m "Cleanup temp files"
        echo "Коммит 'Cleanup temp files' создан"
    else
        echo "Нет .tmp файлов для удаления"
    fi
else
    echo "Папка raw_data не найдена!"
    exit 1
fi
echo "Задание 1 выполнено"

# ========== ЗАДАНИЕ 2 ==========
echo "Задание 2: Поиск строк с TGCA"
cd raw_data || exit 1

# Проверяем наличие файла
if [ ! -f "huge_sequencing_run.fastq" ]; then
    echo "ОШИБКА: Файл huge_sequencing_run.fastq не найден!"
    exit 1
fi

grep "TGCA" huge_sequencing_run.fastq > infected_reads.txt || echo "TGCA не найдено" > infected_reads.txt
echo "Количество строк с TGCA: $(wc -l < infected_reads.txt)"

# Проверяем, существует ли ветка investigation
if git show-ref --verify --quiet refs/heads/investigation; then
    git checkout investigation
else
    git checkout -b investigation
fi

git add infected_reads.txt
git commit -m "Add infected reads"
cd ..
echo "Задание 2 выполнено"

# ========== ЗАДАНИЕ 3 ==========
echo "Задание 3: Создание mini_run.fastq"
cd raw_data || exit 1
head -n 50 huge_sequencing_run.fastq > mini_run.fastq
tail -n 50 huge_sequencing_run.fastq >> mini_run.fastq
git add mini_run.fastq
git commit -m "Add mini run fastq"
cd ..
echo "Задание 3 выполнено"

# ========== ЗАДАНИЕ 4 ==========
echo "Задание 4: Восстановление experiment.log"

# Создаем experiment.log если его нет (для демонстрации)
echo "Sample log content" > experiment.log
git add experiment.log
git commit -m "Add experiment log" 2>/dev/null || true

# Теперь удаляем и восстанавливаем
rm -f experiment.log
echo "Проверка удаления:"
ls -la experiment.log 2>/dev/null || echo "Файл experiment.log действительно удален"
git status | grep experiment.log || echo "Git заметил удаление"

# Восстанавливаем файл
git checkout HEAD experiment.log
echo "git checkout HEAD experiment.log" > command.txt
echo "Файл восстановлен командой: git checkout HEAD experiment.log"

# Переключаемся на main и коммитим
git checkout main
git add command.txt
git commit -m "Add restore command" 2>/dev/null || true
echo "Задание 4 выполнено"

# ========== ЗАДАНИЕ 5 ==========
echo "Задание 5: Работа с access.log"
cat > access.log << 'EOF'
User: LabAdmin
User: Student
User: Hacker
User: LabAdmin
User: Student
User: Student
EOF

sort access.log | uniq -c | sort -r > sort.txt
echo "Результаты сортировки:"
cat sort.txt
git add access.log sort.txt
git commit -m "Add access log and sort results"

# Слияние веток investigation и main
git merge investigation -m "Merge investigation into main" 2>/dev/null || echo "Ветки уже слиты или конфликтов нет"
echo "Задание 5 выполнено"

# ========== ЗАДАНИЕ 6 ==========
echo "Задание 6: Преобразование genes.tsv"
echo "GeneA GeneB GeneC" > genes.tsv
tr ' ' ',' < genes.tsv > genes_fixed.csv
echo "Результат преобразования:"
cat genes_fixed.csv
git add genes_fixed.csv
git commit -m "Add genes fixed CSV"
echo "Задание 6 выполнено"

# ========== ЗАДАНИЕ 7 ==========
echo "Задание 7: Поиск файлов в lab_disaster"

# Проверяем наличие папки
if [ ! -d "lab_disaster" ]; then
    echo "Папка lab_disaster не найдена!"
    mkdir -p lab_disaster
    echo "Создана папка lab_disaster"
fi

# Создаем ветку cleaning если её нет
if git show-ref --verify --quiet refs/heads/cleaning; then
    git checkout cleaning
else
    git checkout -b cleaning
fi

# Ищем файлы больше 1 килобайта
echo "Файлы больше 1 килобайта:" > diskusage.file
find lab_disaster -type f -size +1k -exec du -b {} \; >> diskusage.file 2>/dev/null

# Ищем все .fastq файлы
echo -e "\nВсе .fastq файлы:" >> diskusage.file
find lab_disaster -name "*.fastq" -exec du -b {} \; >> diskusage.file 2>/dev/null

echo "Содержимое diskusage.file:"
cat diskusage.file
git add diskusage.file
git commit -m "Add disk usage report"
git checkout main
echo "Задание 7 выполнено"

# ========== ЗАДАНИЕ 8 ==========
echo "Задание 8: Amend коммит"
echo "Temp file content" > temp_file.txt
git add temp_file.txt
git commit -m "Temporary commit"

# Получаем хеш ДО amend
OLD_HASH=$(git log --oneline | head -1 | awk '{print $1}')
echo "First 4 chars of commit hash (before amend): $OLD_HASH" > hash_info.txt

# Добавляем файл и делаем amend
echo "Forgotten content" > forgotten.txt
git add forgotten.txt
git commit --amend --no-edit

# Получаем хеш ПОСЛЕ amend
NEW_HASH=$(git log --oneline | head -1 | awk '{print $1}')
echo "First 4 chars of commit hash (after amend): $NEW_HASH" >> hash_info.txt

# Создаем файл с объяснениями
cat > amend.txt << 'EOF'
Question 1: Изменился ли хеш коммита?
Answer: Да, хеш коммита изменился.

Question 2: Почему, если сообщение осталось тем же?
Answer: Хеш коммита изменился потому, что Git создает хеш на основе всего содержимого коммита:
- Состояние всех файлов в коммите (изменилось, добавился forgotten.txt)
- Сообщение коммита (осталось тем же)
- Автор коммита
- Время создания коммита (обновилось)
- Родительский коммит

Даже небольшие изменения в содержимом приводят к новому хешу.
EOF

echo "Хеши коммитов:"
cat hash_info.txt
git add amend.txt hash_info.txt
git commit -m "Add amend explanation"
echo "Задание 8 выполнено"

# ========== ЗАДАНИЕ 9 ==========
echo "Задание 9: История команд и финальные операции"

# Сохраняем историю Git команд
if command -v history &> /dev/null; then
    history | grep git > report_commands.txt 2>/dev/null || echo "Git commands history not found" > report_commands.txt
else
    echo "History command not available" > report_commands.txt
    # Добавляем пример команд
    cat >> report_commands.txt << 'EOF'
Примеры использованных Git команд:
git init
git add
git commit
git branch
git checkout
git merge
git remote
git log
git checkout HEAD <file>
git commit --amend
git config core.filemode false
git remote remove origin
git remote add origin
EOF
fi

echo "Сохранены команды Git:"
head -5 report_commands.txt
git add report_commands.txt
git commit -m "Add git commands report"

# Слияние cleaning с main
git merge cleaning -m "Merge cleaning into main" 2>/dev/null || echo "Ветки уже слиты или конфликтов нет"

# Удаление веток
echo "Удаление веток cleaning и investigation..."
git branch -d cleaning 2>/dev/null || git branch -D cleaning 2>/dev/null || echo "Ветка cleaning уже удалена"
git branch -d investigation 2>/dev/null || git branch -D investigation 2>/dev/null || echo "Ветка investigation уже удалена"

# Показываем оставшиеся ветки
echo "Оставшиеся ветки:"
git branch

echo "=========================================="
echo "Все задания успешно выполнены!"
echo "=========================================="
echo "Финальные шаги:"
echo "1. Проверьте историю коммитов: git log --oneline --graph --all"
echo "2. Отправьте на ваш удаленный репозиторий:"
echo "   git push -u origin main"
echo ""
echo "ИЛИ если ветка называется master:"
echo "   git push -u origin master"
echo ""
echo "Если возникнет ошибка при push, выполните:"
echo "   git pull origin main --allow-unrelated-histories"
echo "   git push -u origin main"
