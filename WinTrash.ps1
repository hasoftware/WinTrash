<#
.SYNOPSIS
    WinTrash Toolkit - ALL-IN-ONE. Quét 18 loại tàn dư ứng dụng Windows,
    cho CHỌN TỪNG MỤC bằng phím Space rồi mới dọn (luôn backup trước khi xóa).

.DESCRIPTION
    Một file duy nhất gồm:
      - Menu đa ngôn ngữ (Tiếng Việt / English / 中文 / Русский)
      - 2 vai trò: User / Developer
      - 18 module quét (PATH, EnvVars, Folders, Services, Startup, Tasks,
        Uninstall, AppPaths, Shortcuts, Firewall, Defender, Certs, IFEO,
        NativeMsg, Protocols, VendorReg, Docker, WSL)
      - Dọn dẹp TƯƠNG TÁC: danh sách checkbox, ↑↓ di chuyển, Space chọn,
        A chọn hết, N bỏ hết, Enter xác nhận, Esc hủy
      - Mọi thao tác xóa đều backup (.reg / .xml / Recycle Bin / log)
      - [Developer] Quét cache toolchain + cài DevRadar, Claudefy (có spinner)
      - Sắp xếp Downloads an toàn (chỉ file rời ở gốc, chọn nhóm, có Undo)

.PARAMETER Language
    vi | en | zh | ru - bỏ qua bước hỏi ngôn ngữ.

.PARAMETER Role
    User | Developer - bỏ qua bước hỏi vai trò.

.PARAMETER Action
    Chạy thẳng: scan | clean | downloads | devscan | install-devradar | install-claudefy

.EXAMPLE
    .\WinTrash.ps1
    .\WinTrash.ps1 -Language vi -Role Developer -Action scan

.NOTES
    Giấy phép MIT. Tương thích Windows PowerShell 5.1 và PowerShell 7+.
#>

[CmdletBinding()]
param(
    [ValidateSet('vi', 'en', 'zh', 'ru')]
    [string]$Language,
    [ValidateSet('User', 'Developer')]
    [string]$Role,
    [ValidateSet('scan', 'clean', 'downloads', 'devscan', 'install-devradar', 'install-claudefy', 'restore', 'temp', 'schedule', 'clean-resume')]
    [string]$Action
)

$ErrorActionPreference = 'Continue'
# Tắt progress bar mặc định của các cmdlet hệ thống (Get/Remove-NetFirewallRule,
# Invoke-WebRequest...) - chúng vẽ khối xanh to chèn lên giao diện của mình
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$script:WinTrashVersion = [version]'1.3.0'
$script:UpdateRawBase = 'https://raw.githubusercontent.com/hasoftware/WinTrash/main'

# ════════════════════════════ I18N ════════════════════════════
$i18n = @{
    vi = @{
        ChooseLang  = 'Chọn ngôn ngữ / Choose language / 选择语言 / Выберите язык:'
        ChooseRole  = 'Bạn là ai?'
        RoleUser    = 'Người dùng thường'
        RoleDev     = 'Developer (thêm quét toolchain, cài DevRadar + Claudefy)'
        MenuTitle   = 'WINTRASH TOOLKIT'
        MenuScan    = 'Quét tổng thể 18 loại tàn dư (chỉ đọc + báo cáo HTML)'
        MenuClean   = 'Quét & DỌN DẸP - tự chọn từng mục bằng phím Space'
        MenuDl      = 'Sắp xếp Downloads (xem trước, chọn nhóm, có Undo)'
        MenuDevScan = '[Dev] Quét cache toolchain + dọn cache mồ côi'
        MenuRadar   = '[Dev] Cài DevRadar'
        MenuClaudefy= '[Dev] Cài Claudefy'
        MenuExit    = 'Thoát'
        Prompt      = 'Chọn số'
        Invalid     = 'Lựa chọn không hợp lệ.'
        PressEnter  = 'Nhấn Enter để tiếp tục...'
        Init        = 'Đang khởi tạo'
        Scanning    = 'Đang quét'
        PickerHelp  = '↑/↓ di chuyển  Space chọn  A hết  N bỏ  F lọc mức độ  I ẩn vĩnh viễn  Enter xác nhận  Esc hủy'
        MenuTemp    = 'Dọn file tạm an toàn (Temp > 24 giờ)'
        MenuRestore = 'Khôi phục từ backup (hoàn tác lần dọn trước)'
        MenuSched   = 'Bật/tắt lịch quét tự động hàng tháng'
        IgnoredHidden = 'Đã ẩn {0} mục theo danh sách bỏ qua (wintrash.ignore.json)'
        DiffFirst   = 'Lần quét đầu tiên đã được lưu để so sánh cho lần sau.'
        DiffNew     = 'So với lần quét {0}: +{1} mục mới, {2} mục đã biến mất'
        RestoreTitle= 'Các bản backup có sẵn (nhập số để khôi phục, Enter để thoát):'
        RestoreNothing = 'Chưa có bản backup nào trong WinTrashBackups.'
        RestoreDone = 'Khôi phục xong: {0} OK, {1} lỗi.'
        TempTitle   = 'DỌN FILE TẠM AN TOÀN - chỉ xóa file cũ hơn 24 giờ'
        TempConfirm = 'Xóa {0:N0} MB file tạm cũ? [y/N]'
        TempDone    = 'Đã giải phóng {0:N0} MB ({1} file).'
        TempNothing = 'Không có file tạm cũ nào đáng kể.'
        SchedCreated= 'Đã tạo lịch quét hàng tháng: task "{0}" (ngày 1, 09:03).'
        SchedRemoved= 'Đã xóa lịch quét hàng tháng.'
        SchedAskRemove = 'Lịch quét đã tồn tại. Xóa nó? [y/N]'
        Back        = 'Quay lại'
        MenuSwitch  = 'Đổi ngôn ngữ / vai trò'
        UpdateCheck = 'Đang kiểm tra phiên bản mới...'
        UpdateFound = 'Có phiên bản mới {0} (bạn đang dùng {1}). Cập nhật ngay? [y/N]'
        UpdateWhatsNew = 'CÓ GÌ MỚI trong {0}:'
        UpdateMoreNotes = '... và {0} dòng nữa - xem đầy đủ: CHANGELOG.md trên GitHub'
        UpdateDone  = 'Cập nhật thành công - đang khởi động lại...'
        UpdateFail  = 'Không cập nhật được: {0} - tiếp tục dùng phiên bản hiện tại.'
        ElevateAsk  = '{0}/{1} mục cần quyền Administrator. Mở cửa sổ Admin để dọn TOÀN BỘ? [y = mở Admin / n = chỉ dọn phần làm được]'
        ElevateLaunched = 'Đã mở cửa sổ Administrator - phần dọn tiếp tục ở đó (quét lại nhanh rồi tự dọn đúng các mục bạn đã chọn).'
        SkippedAdmin = 'Đã bỏ qua {0} mục cần Administrator.'
        ResumeNothing = 'Không còn mục nào khớp danh sách đã chọn (có thể đã được dọn).'
        MultiUserAsk = 'Máy có {0} user khác ({1}). Quét cả hồ sơ của họ? [y/N]'
        MultiUserOn  = 'Sẽ quét thêm hồ sơ của {0} user khác (AppData, Startup, Run-key, Shortcuts).'
        PickerTitle = 'CHỌN CÁC MỤC MUỐN DỌN (chưa xóa gì cho tới khi bạn xác nhận)'
        NothingFound= 'Không phát hiện mục nào có thể dọn. Máy sạch!'
        NothingSel  = 'Không chọn mục nào - không làm gì cả.'
        ConfirmDel  = 'Xóa {0} mục đã chọn? Mọi mục đều được backup trước. [y/N]'
        Cleaning    = 'Đang dọn dẹp'
        CleanDone   = 'Hoàn tất: {0} OK, {1} lỗi. Backup tại: {2}'
        NeedAdmin   = '(một số mục cần Administrator - mục lỗi hãy chạy lại bằng quyền admin)'
        NeedNode    = 'Cần Node.js >= 18: https://nodejs.org (hoặc: winget install OpenJS.NodeJS.LTS)'
        Installing  = 'Đang cài đặt'
        InstallOk   = 'Cài đặt xong.'
        InstallFail = 'Cài đặt lỗi - xem log: {0}'
        NoInteract  = 'Console không tương tác - bỏ qua bước chọn (dùng -Action scan để xem báo cáo).'
        DlTitle     = 'SẮP XẾP DOWNLOADS - chọn nhóm muốn áp dụng'
        DlNothing   = 'Không có file rời nào cần sắp xếp.'
        DlDone      = 'Đã sắp xếp {0} file. Hoàn tác: {1}'
        ReportSaved = 'Báo cáo HTML: {0}'
        NoteVi      = 'Ghi chú: chi tiết kỹ thuật của báo cáo hiện bằng tiếng Việt.'
    }
    en = @{
        ChooseLang  = 'Chọn ngôn ngữ / Choose language / 选择语言 / Выберите язык:'
        ChooseRole  = 'Who are you?'
        RoleUser    = 'Regular user'
        RoleDev     = 'Developer (adds toolchain scan, DevRadar + Claudefy install)'
        MenuTitle   = 'WINTRASH TOOLKIT'
        MenuScan    = 'Full scan - 18 leftover types (read-only + HTML report)'
        MenuClean   = 'Scan & CLEAN - pick items one by one with Space'
        MenuDl      = 'Organize Downloads (preview, pick groups, undo available)'
        MenuDevScan = '[Dev] Toolchain cache scan + clean orphan caches'
        MenuRadar   = '[Dev] Install DevRadar'
        MenuClaudefy= '[Dev] Install Claudefy'
        MenuExit    = 'Exit'
        Prompt      = 'Enter a number'
        Invalid     = 'Invalid choice.'
        PressEnter  = 'Press Enter to continue...'
        Init        = 'Initializing'
        Scanning    = 'Scanning'
        PickerHelp  = '↑/↓ move  Space toggle  A all  N none  F filter severity  I ignore forever  Enter confirm  Esc cancel'
        MenuTemp    = 'Safe temp cleanup (Temp files > 24h)'
        MenuRestore = 'Restore from backup (undo previous cleanup)'
        MenuSched   = 'Enable/disable monthly auto-scan'
        IgnoredHidden = '{0} items hidden by ignore list (wintrash.ignore.json)'
        DiffFirst   = 'First scan saved as baseline for future comparison.'
        DiffNew     = 'Compared to scan {0}: +{1} new items, {2} items gone'
        RestoreTitle= 'Available backups (enter number to restore, Enter to exit):'
        RestoreNothing = 'No backups found in WinTrashBackups.'
        RestoreDone = 'Restore finished: {0} OK, {1} failed.'
        TempTitle   = 'SAFE TEMP CLEANUP - only files older than 24 hours'
        TempConfirm = 'Delete {0:N0} MB of old temp files? [y/N]'
        TempDone    = 'Freed {0:N0} MB ({1} files).'
        TempNothing = 'No significant old temp files.'
        SchedCreated= 'Monthly scan scheduled: task "{0}" (day 1, 09:03).'
        SchedRemoved= 'Monthly scan schedule removed.'
        SchedAskRemove = 'Schedule already exists. Remove it? [y/N]'
        Back        = 'Back'
        MenuSwitch  = 'Change language / role'
        UpdateCheck = 'Checking for updates...'
        UpdateFound = 'New version {0} available (you have {1}). Update now? [y/N]'
        UpdateWhatsNew = 'WHAT''S NEW in {0} (notes are in Vietnamese):'
        UpdateMoreNotes = '... and {0} more lines - full notes: CHANGELOG.md on GitHub'
        UpdateDone  = 'Updated successfully - restarting...'
        UpdateFail  = 'Update failed: {0} - continuing with current version.'
        ElevateAsk  = '{0}/{1} items require Administrator. Open an Admin window to clean EVERYTHING? [y = elevate / n = clean what is possible now]'
        ElevateLaunched = 'Administrator window opened - cleanup continues there (quick re-scan, then cleans exactly what you picked).'
        SkippedAdmin = 'Skipped {0} items that require Administrator.'
        ResumeNothing = 'No items match the saved selection (they may already be cleaned).'
        MultiUserAsk = 'This machine has {0} other user(s) ({1}). Scan their profiles too? [y/N]'
        MultiUserOn  = 'Will also scan {0} other user profile(s) (AppData, Startup, Run keys, Shortcuts).'
        PickerTitle = 'SELECT ITEMS TO CLEAN (nothing is deleted until you confirm)'
        NothingFound= 'Nothing cleanable found. Your machine is clean!'
        NothingSel  = 'Nothing selected - no action taken.'
        ConfirmDel  = 'Delete {0} selected items? Everything is backed up first. [y/N]'
        Cleaning    = 'Cleaning'
        CleanDone   = 'Done: {0} OK, {1} failed. Backup at: {2}'
        NeedAdmin   = '(some items need Administrator - re-run elevated for failed ones)'
        NeedNode    = 'Node.js >= 18 required: https://nodejs.org (or: winget install OpenJS.NodeJS.LTS)'
        Installing  = 'Installing'
        InstallOk   = 'Install finished.'
        InstallFail = 'Install failed - see log: {0}'
        NoInteract  = 'Console is not interactive - selection skipped (use -Action scan for a report).'
        DlTitle     = 'ORGANIZE DOWNLOADS - pick groups to apply'
        DlNothing   = 'No loose files to organize.'
        DlDone      = 'Organized {0} files. Undo: {1}'
        ReportSaved = 'HTML report: {0}'
        NoteVi      = 'Note: technical report details are currently in Vietnamese.'
    }
    zh = @{
        ChooseLang  = 'Chọn ngôn ngữ / Choose language / 选择语言 / Выберите язык:'
        ChooseRole  = '您是谁？'
        RoleUser    = '普通用户'
        RoleDev     = '开发者（额外：工具链扫描，安装 DevRadar + Claudefy）'
        MenuTitle   = 'WINTRASH TOOLKIT'
        MenuScan    = '全面扫描 - 18 类残留（只读 + HTML 报告）'
        MenuClean   = '扫描并清理 - 用空格键逐项选择'
        MenuDl      = '整理下载文件夹（预览、选组、可撤销）'
        MenuDevScan = '[Dev] 工具链缓存扫描 + 清理孤立缓存'
        MenuRadar   = '[Dev] 安装 DevRadar'
        MenuClaudefy= '[Dev] 安装 Claudefy'
        MenuExit    = '退出'
        Prompt      = '请输入编号'
        Invalid     = '无效的选择。'
        PressEnter  = '按 Enter 继续...'
        Init        = '正在初始化'
        Scanning    = '正在扫描'
        PickerHelp  = '↑/↓ 移动  空格 选择  A 全选  N 全不选  F 按级别筛选  I 永久忽略  Enter 确认  Esc 取消'
        MenuTemp    = '安全清理临时文件（超过 24 小时）'
        MenuRestore = '从备份恢复（撤销上次清理）'
        MenuSched   = '启用/禁用每月自动扫描'
        IgnoredHidden = '已按忽略列表隐藏 {0} 项 (wintrash.ignore.json)'
        DiffFirst   = '首次扫描已保存，供下次对比。'
        DiffNew     = '与 {0} 的扫描相比：新增 {1} 项，消失 {2} 项'
        RestoreTitle= '可用备份（输入编号恢复，Enter 退出）：'
        RestoreNothing = 'WinTrashBackups 中没有备份。'
        RestoreDone = '恢复完成：{0} 成功，{1} 失败。'
        TempTitle   = '安全清理临时文件 - 仅删除超过 24 小时的文件'
        TempConfirm = '删除 {0:N0} MB 旧临时文件？[y/N]'
        TempDone    = '已释放 {0:N0} MB（{1} 个文件）。'
        TempNothing = '没有明显的旧临时文件。'
        SchedCreated= '已创建每月扫描计划：任务 "{0}"（1 号 09:03）。'
        SchedRemoved= '已删除每月扫描计划。'
        SchedAskRemove = '计划已存在。删除它？[y/N]'
        Back        = '返回'
        MenuSwitch  = '更改语言 / 角色'
        UpdateCheck = '正在检查更新...'
        UpdateFound = '发现新版本 {0}（当前 {1}）。立即更新？[y/N]'
        UpdateWhatsNew = '{0} 版本更新内容（越南语）：'
        UpdateMoreNotes = '... 还有 {0} 行 - 完整内容见 GitHub 上的 CHANGELOG.md'
        UpdateDone  = '更新成功 - 正在重新启动...'
        UpdateFail  = '更新失败：{0} - 继续使用当前版本。'
        ElevateAsk  = '{0}/{1} 项需要管理员权限。打开管理员窗口清理全部？[y = 提权 / n = 仅清理当前可行的]'
        ElevateLaunched = '已打开管理员窗口 - 清理将在那里继续（快速重扫后清理您选择的项目）。'
        SkippedAdmin = '已跳过 {0} 个需要管理员权限的项目。'
        ResumeNothing = '没有与已保存选择匹配的项目（可能已被清理）。'
        MultiUserAsk = '本机有 {0} 个其他用户（{1}）。也扫描他们的配置文件？[y/N]'
        MultiUserOn  = '将同时扫描 {0} 个其他用户的配置文件（AppData、启动项、Run 键、快捷方式）。'
        PickerTitle = '选择要清理的项目（确认前不会删除任何内容）'
        NothingFound= '未发现可清理的项目。您的电脑很干净！'
        NothingSel  = '未选择任何项目 - 不执行任何操作。'
        ConfirmDel  = '删除选中的 {0} 项？所有内容都会先备份。[y/N]'
        Cleaning    = '正在清理'
        CleanDone   = '完成：{0} 成功，{1} 失败。备份位置：{2}'
        NeedAdmin   = '（部分项目需要管理员权限 - 失败的项目请以管理员身份重新运行）'
        NeedNode    = '需要 Node.js >= 18：https://nodejs.org（或：winget install OpenJS.NodeJS.LTS）'
        Installing  = '正在安装'
        InstallOk   = '安装完成。'
        InstallFail = '安装失败 - 查看日志：{0}'
        NoInteract  = '控制台不可交互 - 跳过选择（使用 -Action scan 查看报告）。'
        DlTitle     = '整理下载文件夹 - 选择要应用的分组'
        DlNothing   = '没有需要整理的零散文件。'
        DlDone      = '已整理 {0} 个文件。撤销：{1}'
        ReportSaved = 'HTML 报告：{0}'
        NoteVi      = '注：报告的技术细节目前为越南语。'
    }
    ru = @{
        ChooseLang  = 'Chọn ngôn ngữ / Choose language / 选择语言 / Выберите язык:'
        ChooseRole  = 'Кто вы?'
        RoleUser    = 'Обычный пользователь'
        RoleDev     = 'Разработчик (плюс сканирование тулчейнов, DevRadar + Claudefy)'
        MenuTitle   = 'WINTRASH TOOLKIT'
        MenuScan    = 'Полное сканирование - 18 типов остатков (только чтение + HTML)'
        MenuClean   = 'Сканировать и ОЧИСТИТЬ - выбор пунктов пробелом'
        MenuDl      = 'Организация Downloads (предпросмотр, выбор групп, откат)'
        MenuDevScan = '[Dev] Кэши тулчейнов + очистка кэшей-сирот'
        MenuRadar   = '[Dev] Установить DevRadar'
        MenuClaudefy= '[Dev] Установить Claudefy'
        MenuExit    = 'Выход'
        Prompt      = 'Введите номер'
        Invalid     = 'Неверный выбор.'
        PressEnter  = 'Нажмите Enter для продолжения...'
        Init        = 'Инициализация'
        Scanning    = 'Сканирование'
        PickerHelp  = '↑/↓ перемещение  Пробел выбор  A все  N ничего  F фильтр  I игнорировать  Enter подтвердить  Esc отмена'
        MenuTemp    = 'Безопасная очистка Temp (файлы старше 24 ч)'
        MenuRestore = 'Восстановление из бэкапа (откат прошлой очистки)'
        MenuSched   = 'Вкл/выкл ежемесячное автосканирование'
        IgnoredHidden = 'Скрыто {0} пунктов по списку игнорирования (wintrash.ignore.json)'
        DiffFirst   = 'Первое сканирование сохранено для будущего сравнения.'
        DiffNew     = 'По сравнению со сканом {0}: +{1} новых, {2} исчезло'
        RestoreTitle= 'Доступные бэкапы (номер для восстановления, Enter - выход):'
        RestoreNothing = 'Бэкапов в WinTrashBackups нет.'
        RestoreDone = 'Восстановление: {0} OK, {1} ошибок.'
        TempTitle   = 'БЕЗОПАСНАЯ ОЧИСТКА TEMP - только файлы старше 24 часов'
        TempConfirm = 'Удалить {0:N0} МБ старых временных файлов? [y/N]'
        TempDone    = 'Освобождено {0:N0} МБ ({1} файлов).'
        TempNothing = 'Значимых старых временных файлов нет.'
        SchedCreated= 'Ежемесячное сканирование создано: задача "{0}" (1-е число, 09:03).'
        SchedRemoved= 'Расписание удалено.'
        SchedAskRemove = 'Расписание уже существует. Удалить? [y/N]'
        Back        = 'Назад'
        MenuSwitch  = 'Сменить язык / роль'
        UpdateCheck = 'Проверка обновлений...'
        UpdateFound = 'Доступна новая версия {0} (у вас {1}). Обновить сейчас? [y/N]'
        UpdateWhatsNew = 'ЧТО НОВОГО в версии {0} (описание на вьетнамском):'
        UpdateMoreNotes = '... и ещё {0} строк - полный список: CHANGELOG.md на GitHub'
        UpdateDone  = 'Обновление выполнено - перезапуск...'
        UpdateFail  = 'Ошибка обновления: {0} - продолжаем с текущей версией.'
        ElevateAsk  = '{0}/{1} пунктов требуют прав администратора. Открыть окно администратора для полной очистки? [y / n = очистить возможное]'
        ElevateLaunched = 'Окно администратора открыто - очистка продолжится там (пересканирование, затем очистка выбранного).'
        SkippedAdmin = 'Пропущено пунктов, требующих администратора: {0}.'
        ResumeNothing = 'Нет пунктов, соответствующих сохранённому выбору (возможно, уже очищены).'
        MultiUserAsk = 'На машине есть другие пользователи: {0} ({1}). Сканировать и их профили? [y/N]'
        MultiUserOn  = 'Будут просканированы профили других пользователей: {0} (AppData, автозагрузка, Run-ключи, ярлыки).'
        PickerTitle = 'ВЫБЕРИТЕ ПУНКТЫ ДЛЯ ОЧИСТКИ (ничего не удаляется до подтверждения)'
        NothingFound= 'Ничего для очистки не найдено. Ваш компьютер чист!'
        NothingSel  = 'Ничего не выбрано - действий не выполнено.'
        ConfirmDel  = 'Удалить выбранные пункты ({0})? Всё сначала резервируется. [y/N]'
        Cleaning    = 'Очистка'
        CleanDone   = 'Готово: {0} OK, {1} ошибок. Бэкап: {2}'
        NeedAdmin   = '(некоторым пунктам нужны права администратора)'
        NeedNode    = 'Требуется Node.js >= 18: https://nodejs.org (или: winget install OpenJS.NodeJS.LTS)'
        Installing  = 'Установка'
        InstallOk   = 'Установка завершена.'
        InstallFail = 'Ошибка установки - см. лог: {0}'
        NoInteract  = 'Консоль неинтерактивна - выбор пропущен (используйте -Action scan).'
        DlTitle     = 'ОРГАНИЗАЦИЯ DOWNLOADS - выберите группы'
        DlNothing   = 'Нет файлов для организации.'
        DlDone      = 'Организовано файлов: {0}. Откат: {1}'
        ReportSaved = 'HTML-отчёт: {0}'
        NoteVi      = 'Примечание: технические детали отчёта пока на вьетнамском.'
    }
}

# ════════════════════════ CONSOLE HELPERS ════════════════════════

function Test-Interactive {
    try { return -not [Console]::IsInputRedirected } catch { return $false }
}

$script:spinIdx = 0
function Get-SpinFrame {
    $frames = '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
    $script:spinIdx++
    return $frames[$script:spinIdx % $frames.Count]
}

# Terminal hiện đại (Windows Terminal, ConEmu, PS7...) hỗ trợ true-color ANSI:
# dùng RGB thật để màu KHÔNG bị theme remap (tránh tích xanh hóa... tím).
# Console cũ fallback về ConsoleColor thường.
$script:ansiOk = [bool]($env:WT_SESSION -or $env:TERM_PROGRAM -or ($env:ConEmuANSI -eq 'ON') -or $PSVersionTable.PSVersion.Major -ge 7)
$script:trueColors = @{
    'Green'    = '0;200;83'
    'Red'      = '239;83;80'
    'Yellow'   = '255;202;40'
    'Cyan'     = '38;198;218'
    'Blue'     = '66;165;245'
    'Gray'     = '189;189;189'
    'DarkGray' = '130;130;130'
    'White'    = '255;255;255'
}

function Get-SeverityColor {
    param([string]$Severity)
    switch ($Severity) {
        'High'   { return [ConsoleColor]::Red }
        'Medium' { return [ConsoleColor]::Yellow }
        default  { return [ConsoleColor]::Blue }
    }
}

function Write-C {
    # Write-Host có màu: true-color ANSI nếu terminal hỗ trợ, ngược lại ConsoleColor
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray, [switch]$NoNewline)
    $colorName = [string]$Color
    if ($script:ansiOk -and $script:trueColors.ContainsKey($colorName)) {
        $e = [char]27
        Write-Host ("{0}[38;2;{1}m{2}{0}[0m" -f $e, $script:trueColors[$colorName], $Text) -NoNewline:$NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color -NoNewline:$NoNewline
    }
}

function Show-Banner {
    # Banner ASCII chữ to HASOFTWARE - hiển thị khi khởi động
    param([string]$Tagline = '')
    $redirected = $false
    try { $redirected = [Console]::IsOutputRedirected } catch {}
    if ($redirected) {
        Write-Host '=== HASOFTWARE ==='
        if ($Tagline) { Write-Host $Tagline }
        return
    }
    # Font khối 5 dòng, mỗi chữ 5 cột - ghép bằng code để không sai pixel
    $glyphs = @{
        'H' = @('#   #', '#   #', '#####', '#   #', '#   #')
        'A' = @(' ### ', '#   #', '#####', '#   #', '#   #')
        'S' = @(' ####', '#    ', ' ### ', '    #', '#### ')
        'O' = @(' ### ', '#   #', '#   #', '#   #', ' ### ')
        'F' = @('#####', '#    ', '#### ', '#    ', '#    ')
        'T' = @('#####', '  #  ', '  #  ', '  #  ', '  #  ')
        'W' = @('#   #', '#   #', '# # #', '## ##', '#   #')
        'R' = @('#### ', '#   #', '#### ', '#  # ', '#   #')
        'E' = @('#####', '#    ', '#### ', '#    ', '#####')
    }
    $text = 'HASOFTWARE'
    Write-Host ''
    for ($row = 0; $row -lt 5; $row++) {
        $line = ''
        foreach ($ch in $text.ToCharArray()) {
            $line += $glyphs[[string]$ch][$row] + ' '
        }
        $line = $line.Replace('#', [string][char]0x2588)   # khối đặc █
        # Gradient cyan -> xanh lá theo từng dòng
        $rgb = switch ($row) {
            0 { '0;229;255' } 1 { '0;216;212' } 2 { '0;204;170' } 3 { '0;202;125' } default { '0;200;83' }
        }
        if ($script:ansiOk) {
            $e = [char]27
            Write-Host ("  {0}[38;2;{1}m{2}{0}[0m" -f $e, $rgb, $line)
        } else {
            Write-Host ('  ' + $line) -ForegroundColor Cyan
        }
    }
    if ($Tagline) {
        Write-C ('  ' + $Tagline) -Color DarkGray
        Write-Host ''
    }
    Write-Host ''
}

function Write-StatusLine {
    # In dòng trạng thái đè tại chỗ (kiểu npm/cargo) - KHÔNG dùng Write-Progress
    # -Persist: dòng chốt (giữ lại + xuống dòng). Khi output bị redirect (pipeline/CI):
    # các frame spinner bị bỏ qua, chỉ in dòng chốt để log sạch.
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::DarkGray, [switch]$Persist)
    $redirected = $false
    try { $redirected = [Console]::IsOutputRedirected } catch {}
    if ($redirected) {
        if ($Persist -and $Text) { Write-Host $Text -ForegroundColor $Color }
        return
    }
    $w = 120
    try { $w = [Console]::WindowWidth - 1 } catch {}
    if ($Text.Length -gt $w) { $Text = $Text.Substring(0, $w - 1) + '…' }
    Write-Host "`r" -NoNewline
    Write-C ($Text.PadRight($w)) -Color $Color -NoNewline
    if ($Persist) { Write-Host '' }
}

$script:scanStatus = $null        # hashtable đồng bộ chia sẻ với luồng spinner nền
$script:activeSpinner = $null     # handle spinner đang chạy (để dọn khi có sự cố)

function Clear-Screen {
    # Xóa TRIỆT ĐỂ màn hình: viewport + scrollback (ESC[3J) + đưa con trỏ về (0,0).
    # Clear-Host thường chỉ xóa viewport -> đuôi log cũ vẫn lộ ra khi vẽ đè.
    if ($script:ansiOk) {
        $e = [char]27
        [Console]::Write("$e[2J$e[3J$e[H")
    }
    try { [Console]::Clear() } catch { Clear-Host }
    try { [Console]::SetCursorPosition(0, 0) } catch {}
}

function Clear-PendingInput {
    # Nuốt các phím bấm thừa còn nằm trong buffer (Enter bấm liên tục khi đang dọn...)
    # để chúng không "tự trả lời" các prompt kế tiếp làm nhảy màn hình
    try { while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) } } catch {}
}

function Start-ScanSpinner {
    <# Spinner chạy trên RUNSPACE NỀN riêng - quay đều 80ms/frame kể cả khi
       luồng chính đang bận quét (hết cảnh spinner đứng hình ở module lâu).
       Luồng nền là NGƯỜI GHI DUY NHẤT của dòng trạng thái; luồng chính chỉ
       cập nhật text qua hashtable đồng bộ. Trả về handle để Stop. #>
    param([string]$Text)
    $redirected = $false
    try { $redirected = [Console]::IsOutputRedirected } catch {}
    if ($redirected) { return $null }   # pipeline/CI: không animation

    $hash = [hashtable]::Synchronized(@{ Active = $true; Text = $Text; Prefix = $Text; Suspend = $false; Suspended = $false })
    $script:scanStatus = $hash
    $width = 120
    try { $width = [Console]::WindowWidth - 1 } catch {}

    $ps = [PowerShell]::Create()
    [void]$ps.AddScript({
        param($h, $width, $ansiOk)
        $frames = '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
        $e = [char]27
        $i = 0
        while ($h.Active) {
            # Handshake "tạm ngưng": luồng chính cần in dòng kết quả -> spinner
            # tự xóa dòng của mình, báo Suspended rồi đứng chờ (không ghi gì)
            if ($h.Suspend) {
                if (-not $h.Suspended) {
                    [Console]::Write("`r" + (' ' * $width) + "`r")
                    $h.Suspended = $true
                }
                Start-Sleep -Milliseconds 15
                continue
            }
            $h.Suspended = $false
            $line = '{0} {1}' -f $frames[$i % $frames.Count], [string]$h.Text
            if ($line.Length -gt $width) { $line = $line.Substring(0, $width - 1) + [char]0x2026 }
            $line = $line.PadRight($width)
            if ($ansiOk) { [Console]::Write("`r$e[38;2;38;198;218m$line$e[0m") }
            else { [Console]::Write("`r$line") }
            $i++
            Start-Sleep -Milliseconds 80
        }
        # Tự dọn dòng của mình trước khi kết thúc -> không race với luồng chính
        [Console]::Write("`r" + (' ' * $width) + "`r")
    }).AddArgument($hash).AddArgument($width).AddArgument($script:ansiOk)
    $async = $ps.BeginInvoke()
    $handle = @{ PS = $ps; Async = $async; Hash = $hash }
    $script:activeSpinner = $handle
    return $handle
}

function Stop-ScanSpinner {
    param($Handle)
    $script:scanStatus = $null
    $script:activeSpinner = $null
    if ($null -eq $Handle) { return }
    $Handle.Hash.Active = $false
    # Chờ luồng nền vẽ xong frame cuối + tự xóa dòng rồi mới trả quyền ghi console
    [void]$Handle.Async.AsyncWaitHandle.WaitOne(1000)
    try { $Handle.PS.EndInvoke($Handle.Async) } catch {}
    $Handle.PS.Dispose()
}

function Stop-LeakedSpinner {
    # Lưới an toàn: nếu spinner nền còn sống sót (module ném lỗi giữa chừng...)
    # thì dập nó trước khi vẽ màn hình mới - tránh 2 luồng ghi console chồng nhau
    if ($script:activeSpinner) { Stop-ScanSpinner -Handle $script:activeSpinner }
}

function Invoke-WithSpinnerPaused {
    # In output qua "cửa sổ nhường": yêu cầu spinner nền tạm ngưng + xóa dòng,
    # chờ nó xác nhận, chạy $Body (in các dòng persist), rồi cho spinner chạy tiếp
    param($Handle, [scriptblock]$Body)
    if ($null -eq $Handle) { & $Body; return }
    $Handle.Hash.Suspend = $true
    $deadline = [datetime]::Now.AddMilliseconds(500)
    while (-not $Handle.Hash.Suspended -and [datetime]::Now -lt $deadline) { Start-Sleep -Milliseconds 10 }
    try { & $Body } finally { $Handle.Hash.Suspend = $false }
}

function Show-Spinner {
    # Spinner ngắn mang tính khởi động (cosmetic)
    param([string]$Label, [int]$Cycles = 8)
    $frames = '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
    for ($n = 0; $n -lt $Cycles; $n++) {
        Write-Host "`r" -NoNewline
        Write-C ("{0} {1}..." -f $frames[$n % $frames.Count], $Label) -Color Cyan -NoNewline
        Start-Sleep -Milliseconds 70
    }
    Write-Host "`r" -NoNewline
    Write-C ("√ {0}    " -f $Label) -Color Green
}

function Invoke-WithSpinner {
    # Chạy lệnh ngoài (npm/npx) với spinner động; output ghi ra file log
    param([string]$CommandLine, [string]$Label, [string]$LogFile)
    $frames = '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
    $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c ' + $CommandLine + ' > "' + $LogFile + '" 2>&1') -PassThru -WindowStyle Hidden
    $n = 0
    while (-not $proc.HasExited) {
        Write-Host ("`r{0} {1}... " -f $frames[$n % $frames.Count], $Label) -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 120
        $n++
    }
    Write-Host ("`r" + (' ' * ([Console]::WindowWidth - 1)) + "`r") -NoNewline
    return $proc.ExitCode
}

function Show-CheckboxMenu {
    <# Danh sách checkbox tương tác: trả về mảng index các mục được chọn.
       ↑/↓ di chuyển, Space chọn, A chọn hết, N bỏ hết, Enter xác nhận, Esc hủy #>
    param(
        [string[]]$Labels,
        [string]$Title,
        [string]$Help,
        [string[]]$Severities,   # tùy chọn: cột mức độ tô màu (High đỏ / Medium vàng / Info xanh dương)
        [switch]$AllowIgnore     # cho phép phím I: ẩn mục vĩnh viễn (ghi vào wintrash.ignore.json)
    )
    $script:pickerIgnored = @()
    if (-not (Test-Interactive)) { return $null }
    $count = $Labels.Count
    if ($count -eq 0) { return @() }

    $checked = New-Object bool[] $count
    $ignoredFlag = New-Object bool[] $count
    $hasSev = ($null -ne $Severities -and $Severities.Count -eq $count)
    $sevFilters = @($null, 'High', 'Medium', 'Info')   # phím F xoay vòng
    $filterIdx = 0
    $cursor = 0
    $offset = 0
    $winH = [Math]::Max(5, [Console]::WindowHeight - 10)
    $width = [Console]::WindowWidth - 1
    $sevColWidth = if ($hasSev) { 7 } else { 0 }   # 'Medium' + 1 space

    # ---- Các hàm vẽ cục bộ: KHÔNG BAO GIỜ xuống dòng -> không bao giờ cuộn màn hình ----
    function Get-PickerView {
        $filter = $sevFilters[$filterIdx]
        $v = [System.Collections.Generic.List[int]]::new()
        for ($j = 0; $j -lt $count; $j++) {
            if ($ignoredFlag[$j]) { continue }
            if ($hasSev -and $filter -and $Severities[$j] -ne $filter) { continue }
            $v.Add($j)
        }
        return , $v
    }
    function Draw-PickerRow {
        param([int]$RowVisual)
        if ($RowVisual -lt 0 -or $RowVisual -ge $winH) { return }
        [Console]::SetCursorPosition(0, $top + $RowVisual)
        $vIdx = $offset + $RowVisual
        if ($vIdx -ge $view.Count) {
            Write-Host (' ' * $width) -NoNewline
            return
        }
        $idx = $view[$vIdx]
        $mark = if ($checked[$idx]) { '[x]' } else { '[ ]' }
        $ptr = if ($vIdx -eq $cursor) { '>' } else { ' ' }
        $stateColor = if ($vIdx -eq $cursor) { [ConsoleColor]::White } elseif ($checked[$idx]) { [ConsoleColor]::Green } else { [ConsoleColor]::Gray }
        $markColor = if ($checked[$idx]) { [ConsoleColor]::Green } else { $stateColor }
        $labelMax = $width - 7 - $sevColWidth
        $label = $Labels[$idx]
        if ($label.Length -gt $labelMax) { $label = $label.Substring(0, $labelMax - 1) + '…' }
        Write-C (' {0} ' -f $ptr) -Color Cyan -NoNewline
        Write-C $mark -Color $markColor -NoNewline
        Write-Host ' ' -NoNewline
        if ($hasSev) {
            Write-C ('{0,-6} ' -f $Severities[$idx]) -Color (Get-SeverityColor -Severity $Severities[$idx]) -NoNewline
        }
        Write-C $label -Color $stateColor -NoNewline
        $used = 7 + $sevColWidth + $label.Length
        if ($used -lt $width) { Write-Host (' ' * ($width - $used)) -NoNewline }
    }
    function Draw-PickerStatus {
        [Console]::SetCursorPosition(0, $top + $winH)
        $selCount = @($checked | Where-Object { $_ }).Count
        $ignCount = @($ignoredFlag | Where-Object { $_ }).Count
        $filter = $sevFilters[$filterIdx]
        $filterText = if ($filter) { " | F:$filter" } else { '' }
        $ignText = if ($ignCount -gt 0) { " | I:$ignCount" } else { '' }
        $status = ' {0}/{1} | √ {2}{3}{4}' -f ([Math]::Min($cursor + 1, $view.Count)), $view.Count, $selCount, $filterText, $ignText
        if ($status.Length -gt $width) { $status = $status.Substring(0, $width) }
        Write-C ($status.PadRight($width)) -Color Cyan -NoNewline
    }
    function Draw-PickerAll {
        for ($r = 0; $r -lt $winH; $r++) { Draw-PickerRow -RowVisual $r }
        Draw-PickerStatus
    }

    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
    Write-Host $Help -ForegroundColor DarkGray
    # Dành sẵn vùng vẽ cố định (cuộn buffer đúng MỘT lần tại đây) - từ đó về sau
    # mọi thao tác chỉ vẽ đè tại chỗ, màn hình đứng yên tuyệt đối
    for ($r = 0; $r -le $winH; $r++) { Write-Host '' }
    $top = [Console]::CursorTop - ($winH + 1)

    $view = Get-PickerView
    $prevCursorVisible = $true
    try { $prevCursorVisible = [Console]::CursorVisible } catch {}
    try {
        try { [Console]::CursorVisible = $false } catch {}   # ẩn con trỏ nháy khi tương tác
        Draw-PickerAll

        while ($true) {
            $key = [Console]::ReadKey($true)
            $oldCursor = $cursor
            $needFull = $false
            $rebuild = $false
            $touchRow = $false

            switch ($key.Key) {
                'UpArrow'   { if ($cursor -gt 0) { $cursor-- } else { $cursor = [Math]::Max(0, $view.Count - 1) } }
                'DownArrow' { if ($cursor -lt $view.Count - 1) { $cursor++ } else { $cursor = 0 } }
                'PageUp'    { $cursor = [Math]::Max(0, $cursor - $winH) }
                'PageDown'  { $cursor = [Math]::Min([Math]::Max(0, $view.Count - 1), $cursor + $winH) }
                'Home'      { $cursor = 0 }
                'End'       { $cursor = [Math]::Max(0, $view.Count - 1) }
                'Spacebar'  {
                    if ($view.Count -gt 0) {
                        $orig = $view[$cursor]
                        $checked[$orig] = -not $checked[$orig]
                        $touchRow = $true
                    }
                }
                'A'         { foreach ($orig in $view) { $checked[$orig] = $true }; $needFull = $true }
                'N'         { foreach ($orig in $view) { $checked[$orig] = $false }; $needFull = $true }
                'F'         { if ($hasSev) { $filterIdx = ($filterIdx + 1) % $sevFilters.Count; $cursor = 0; $offset = 0; $rebuild = $true } }
                'I'         {
                    if ($AllowIgnore -and $view.Count -gt 0) {
                        $orig = $view[$cursor]
                        $ignoredFlag[$orig] = $true
                        $checked[$orig] = $false
                        $rebuild = $true
                    }
                }
                'Enter'     {
                    $result = [System.Collections.Generic.List[int]]::new()
                    $ign = [System.Collections.Generic.List[int]]::new()
                    for ($j = 0; $j -lt $count; $j++) {
                        if ($checked[$j]) { $result.Add($j) }
                        if ($ignoredFlag[$j]) { $ign.Add($j) }
                    }
                    $script:pickerIgnored = $ign.ToArray()
                    # Bọc dấu phẩy: mảng RỖNG trả thẳng sẽ bị pipeline unwrap thành $null
                    # -> caller nhầm với sentinel "console không tương tác" (return $null ở trên)
                    return , $result.ToArray()
                }
                'Escape'    {
                    $ign = [System.Collections.Generic.List[int]]::new()
                    for ($j = 0; $j -lt $count; $j++) { if ($ignoredFlag[$j]) { $ign.Add($j) } }
                    $script:pickerIgnored = $ign.ToArray()
                    return , @()
                }
            }

            if ($rebuild) {
                $view = Get-PickerView
                if ($view.Count -eq 0 -and $sevFilters[$filterIdx]) { $filterIdx = 0; $view = Get-PickerView }
                if ($cursor -ge $view.Count) { $cursor = [Math]::Max(0, $view.Count - 1) }
                $needFull = $true
            }
            # Cuộn cửa sổ khi con trỏ chạm mép -> phải vẽ lại cả khung
            if ($view.Count -gt 0) {
                if ($cursor -lt $offset) { $offset = $cursor; $needFull = $true }
                elseif ($cursor -ge $offset + $winH) { $offset = $cursor - $winH + 1; $needFull = $true }
            }

            if ($needFull) {
                Draw-PickerAll
            } elseif ($touchRow) {
                # Space: chỉ vẽ lại đúng 1 dòng + thanh trạng thái
                Draw-PickerRow -RowVisual ($cursor - $offset)
                Draw-PickerStatus
            } elseif ($cursor -ne $oldCursor) {
                # Di chuyển trong cùng trang: chỉ vẽ lại 2 dòng (cũ + mới)
                Draw-PickerRow -RowVisual ($oldCursor - $offset)
                Draw-PickerRow -RowVisual ($cursor - $offset)
                Draw-PickerStatus
            }
        }
    }
    finally {
        try { [Console]::CursorVisible = $prevCursorVisible } catch {}
        try {
            [Console]::SetCursorPosition(0, [Math]::Min($top + $winH, [Console]::BufferHeight - 1))
            Write-Host ''
        } catch {}
    }
}

# ════════════════════════ SHARED HELPERS ════════════════════════

function Test-IsAdmin {
    $p = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-Diacritics {
    param([string]$Text)
    $normalized = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = [System.Text.StringBuilder]::new()
    foreach ($c in $normalized.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    return $sb.ToString().Replace([char]0x0111, 'd').Replace([char]0x0110, 'D')
}

function Get-NameTokens {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $Text = Remove-Diacritics -Text $Text
    $tokens = [regex]::Matches($Text.ToLowerInvariant(), '[a-z0-9]{3,}') | ForEach-Object { $_.Value }
    $stopWords = @('the', 'for', 'and', 'inc', 'llc', 'ltd', 'corp', 'corporation',
                   'company', 'software', 'technologies', 'version', 'bit', 'x64', 'x86',
                   'win', 'windows', 'app', 'application', 'setup', 'edition', 'update')
    return @($tokens | Where-Object { $stopWords -notcontains $_ })
}

function Resolve-CommandPath {
    param([string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return $null }
    $cmd = [Environment]::ExpandEnvironmentVariables($CommandLine.Trim())
    if ($cmd.StartsWith('"')) {
        $m = [regex]::Match($cmd, '^"([^"]+)"')
        if ($m.Success) { return $m.Groups[1].Value }
        return $null
    }
    $tokens = $cmd -split ' '
    $invalidChars = [System.IO.Path]::GetInvalidPathChars() + @([char]'"', [char]'<', [char]'>', [char]'|', [char]'*', [char]'?')
    $candidate = ''
    foreach ($tok in $tokens) {
        $candidate = if ($candidate) { "$candidate $tok" } else { $tok }
        # Gặp ký tự không hợp lệ trong đường dẫn (vd: nháy kép giữa lệnh cmd /c "...")
        # thì dừng ghép - phần sau chắc chắn là tham số, không phải đường dẫn
        if ($candidate.IndexOfAny($invalidChars) -ge 0) { break }
        if (Test-Path -LiteralPath $candidate -PathType Leaf -ErrorAction SilentlyContinue) { return $candidate }
        if (Test-Path -LiteralPath "$candidate.exe" -PathType Leaf -ErrorAction SilentlyContinue) { return "$candidate.exe" }
    }
    $m = [regex]::Match($cmd, '^([A-Za-z]:\\.+?\.(exe|bat|cmd|com))(\s|$)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $first = $tokens[0]
    if ($first -match '^[A-Za-z]:\\' -and $first.IndexOfAny($invalidChars) -lt 0) { return $first }
    return $null
}

function Test-ExeMissing {
    param([string]$ExePath)
    if ([string]::IsNullOrWhiteSpace($ExePath)) { return $false }
    $invalidChars = [System.IO.Path]::GetInvalidPathChars() + @([char]'"', [char]'<', [char]'>', [char]'|', [char]'*', [char]'?')
    if ($ExePath.IndexOfAny($invalidChars) -ge 0) { return $false }
    return -not ( (Test-Path -LiteralPath $ExePath -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath "$ExePath.exe" -ErrorAction SilentlyContinue) )
}

function Get-RawRegValue {
    param([string]$Hive, [string]$SubKey, [string]$ValueName)
    $root = if ($Hive -eq 'HKLM') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
    $key = $root.OpenSubKey($SubKey)
    if ($null -eq $key) { return $null }
    try { return $key.GetValue($ValueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
    finally { $key.Close() }
}

function Get-DirSizeMB {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return -1 }
    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
    if ($null -eq $sum) { return 0 }
    return [math]::Round($sum / 1MB, 0)
}

function ConvertTo-RegExePath {
    # 'HKLM:\SOFTWARE\X' hoặc 'Registry::HKEY_LOCAL_MACHINE\...' -> dạng reg.exe hiểu được
    param([string]$PSPath)
    $p = $PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', '' -replace '^Registry::', ''
    $p = $p -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
    return $p
}

$script:appFingerprint = $null
function Get-AppFingerprint {
    if ($script:appFingerprint) { return $script:appFingerprint }
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $installedApps = Get-ItemProperty $uninstallPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName }
    $knownTokens = New-Object 'System.Collections.Generic.HashSet[string]'
    $knownLocations = [System.Collections.Generic.List[string]]::new()
    foreach ($app in $installedApps) {
        foreach ($t in (Get-NameTokens -Text $app.DisplayName)) { [void]$knownTokens.Add($t) }
        if ($app.Publisher) { foreach ($t in (Get-NameTokens -Text $app.Publisher)) { [void]$knownTokens.Add($t) } }
        if ($app.InstallLocation -and $app.InstallLocation.Trim()) {
            $knownLocations.Add($app.InstallLocation.Trim().TrimEnd('\').ToLowerInvariant())
        }
        foreach ($field in @($app.UninstallString, $app.DisplayIcon)) {
            if ([string]::IsNullOrWhiteSpace($field)) { continue }
            $pathPart = $field.Trim()
            if ($pathPart.StartsWith('"')) {
                $m = [regex]::Match($pathPart, '^"([^"]+)"')
                if ($m.Success) { $pathPart = $m.Groups[1].Value }
            } else { $pathPart = ($pathPart -split ',')[0].Trim() }
            if ($pathPart -match '^[A-Za-z]:\\') {
                $parent = Split-Path $pathPart -Parent -ErrorAction SilentlyContinue
                if ($parent) { $knownLocations.Add($parent.TrimEnd('\').ToLowerInvariant()) }
            }
        }
    }
    foreach ($proc in (Get-Process -ErrorAction SilentlyContinue)) {
        foreach ($t in (Get-NameTokens -Text $proc.Name)) { [void]$knownTokens.Add($t) }
        try {
            if ($proc.Path) {
                $procDir = Split-Path $proc.Path -Parent
                if ($procDir) { $knownLocations.Add($procDir.TrimEnd('\').ToLowerInvariant()) }
            }
        } catch {}
    }
    $script:appFingerprint = @{ Tokens = $knownTokens; Locations = $knownLocations }
    return $script:appFingerprint
}

function Test-NameMatchesInstalledApp {
    param([string]$Name)
    $fp = Get-AppFingerprint
    foreach ($ft in @(Get-NameTokens -Text $Name)) {
        if ($fp.Tokens.Contains($ft)) { return $true }
        foreach ($kt in $fp.Tokens) {
            if ($ft.StartsWith($kt) -or ($kt.Length -ge 4 -and $ft.Contains($kt))) { return $true }
            if ($kt.StartsWith($ft) -or ($ft.Length -ge 4 -and $kt.Contains($ft))) { return $true }
        }
    }
    return $false
}

# ════════════════════════ FINDINGS STORE ════════════════════════
# RemoveKind: None | PathEntry | RegValue | RegKey | RecycleDir | RecycleFile |
#             Service | Task | Firewall | DefenderPath | DefenderProcess

$script:findings = [System.Collections.Generic.List[object]]::new()
$script:otherUserProfiles = @()   # hồ sơ user khác được duyệt quét (multi-user, cần admin)

function Get-OtherUserProfiles {
    # Liệt kê hồ sơ user KHÁC trên máy (trừ user hiện tại, hồ sơ hệ thống/Default)
    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $result = [System.Collections.Generic.List[object]]::new()
    foreach ($p in (Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue)) {
        if ($p.Special) { continue }
        if ($p.SID -eq $currentSid) { continue }
        if (-not $p.LocalPath -or -not (Test-Path -LiteralPath $p.LocalPath)) { continue }
        $result.Add([PSCustomObject]@{
            Sid    = $p.SID
            Path   = $p.LocalPath
            Name   = (Split-Path $p.LocalPath -Leaf)
            Loaded = [bool]$p.Loaded   # hive registry đang nạp (user đang đăng nhập)
        })
    }
    return $result.ToArray()
}

$script:offlineMount = 'WinTrash_Offline'   # điểm gắn tạm trong HKEY_USERS cho hive offline

function Invoke-WithOfflineHive {
    <# Nạp NTUSER.DAT của user offline vào HKU\WinTrash_Offline, chạy $Body,
       rồi LUÔN unload (kể cả khi lỗi). Trả về $null nếu không nạp được
       (hive đang bị khóa - user vừa đăng nhập chẳng hạn). #>
    param([string]$HivePath, [scriptblock]$Body)
    # NTUSER.DAT của user khác: non-admin bị từ chối cả quyền đọc -> im lặng bỏ qua
    if (-not (Test-Path -LiteralPath $HivePath -ErrorAction SilentlyContinue)) { return $null }
    & reg.exe load "HKU\$script:offlineMount" $HivePath 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { return $null }
    try {
        return & $Body
    } finally {
        # .NET giữ handle registry -> phải GC trước khi unload mới thành công
        [gc]::Collect()
        [gc]::WaitForPendingFinalizers()
        & reg.exe unload "HKU\$script:offlineMount" 2>$null | Out-Null
    }
}

function Read-OfflineRunKeys {
    # Đọc Run/RunOnce từ hive offline của một profile - trả về mảng entry
    param([string]$ProfilePath)
    $hive = Join-Path $ProfilePath 'NTUSER.DAT'
    $result = Invoke-WithOfflineHive -HivePath $hive -Body {
        $found = [System.Collections.Generic.List[object]]::new()
        foreach ($suffix in 'Run', 'RunOnce') {
            $subKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\$suffix"
            $key = [Microsoft.Win32.Registry]::Users.OpenSubKey("$script:offlineMount\$subKey")
            if ($null -eq $key) { continue }
            try {
                foreach ($valueName in $key.GetValueNames()) {
                    $found.Add([PSCustomObject]@{
                        SubKey  = $subKey
                        Value   = $valueName
                        Command = [string]$key.GetValue($valueName)
                    })
                }
            } finally { $key.Close() }
        }
        return $found.ToArray()
    }
    if ($null -eq $result) { return @() }
    return @($result)
}

function Request-MultiUserScan {
    # Chạy admin + máy có user khác -> hỏi có quét cả hồ sơ của họ không.
    # -Auto: không hỏi, bật luôn (dùng cho clean-resume để khớp danh sách đã chọn)
    param([hashtable]$L, [switch]$Auto)
    $script:otherUserProfiles = @()
    if (-not (Test-IsAdmin)) { return }
    $others = @(Get-OtherUserProfiles)
    if ($others.Count -eq 0) { return }
    if ($Auto) { $script:otherUserProfiles = $others; return }
    if (-not (Test-Interactive)) { return }
    $names = ($others | ForEach-Object { $_.Name }) -join ', '
    $answer = Read-Host ($L.MultiUserAsk -f $others.Count, $names)
    if ($answer -match '^[yY]') {
        $script:otherUserProfiles = $others
        Write-C ($L.MultiUserOn -f $others.Count) -Color Cyan
        Write-Host ''
    }
}

function Get-FindingId {
    # ID ổn định của một phát hiện - dùng cho ignore list và so sánh giữa các lần quét
    param($Finding)
    return '{0}|{1}|{2}' -f $Finding.Category, $Finding.Name, $Finding.Target
}

$script:ignoreFile = Join-Path $PSScriptRoot 'wintrash.ignore.json'
function Get-IgnoreList {
    if (-not (Test-Path -LiteralPath $script:ignoreFile)) { return @() }
    try { return @(Get-Content -LiteralPath $script:ignoreFile -Raw | ConvertFrom-Json) } catch { return @() }
}
function Add-ToIgnoreList {
    param([string[]]$Ids)
    $current = [System.Collections.Generic.List[string]]::new()
    foreach ($existingId in (Get-IgnoreList)) { $current.Add([string]$existingId) }
    foreach ($id in $Ids) { if ($current -notcontains $id) { $current.Add($id) } }
    ConvertTo-Json @($current) | Set-Content -LiteralPath $script:ignoreFile -Encoding UTF8
}

function Save-ScanHistoryAndDiff {
    # Lưu snapshot lần quét này + so sánh với lần trước (mục mới / mục biến mất)
    param([hashtable]$L)
    $histDir = Join-Path $PSScriptRoot 'ScanHistory'
    if (-not (Test-Path -LiteralPath $histDir)) { New-Item -ItemType Directory -Path $histDir -Force | Out-Null }
    $currentIds = @($script:findings | ForEach-Object { Get-FindingId $_ })

    $prevFile = Get-ChildItem -LiteralPath $histDir -Filter 'scan_*.json' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if ($prevFile) {
        try {
            $prev = Get-Content -LiteralPath $prevFile.FullName -Raw | ConvertFrom-Json
            $prevIds = @($prev.Ids)
            $newIds = @($currentIds | Where-Object { $prevIds -notcontains $_ })
            $goneCount = @($prevIds | Where-Object { $currentIds -notcontains $_ }).Count
            Write-Host ''
            $prevDate = [string]$prev.Date
            Write-C ($L.DiffNew -f $prevDate, $newIds.Count, $goneCount) -Color $(if ($newIds.Count -gt 0) { 'Yellow' } else { 'Green' })
            Write-Host ''
            foreach ($newId in ($newIds | Select-Object -First 10)) {
                Write-Host ("    + {0}" -f $newId) -ForegroundColor DarkYellow
            }
            if ($newIds.Count -gt 10) { Write-Host ("    ... và {0} mục nữa" -f ($newIds.Count - 10)) -ForegroundColor DarkGray }
        } catch {}
    } else {
        Write-Host ''
        Write-C $L.DiffFirst -Color DarkGray
        Write-Host ''
    }

    $snapshot = @{ Date = (Get-Date -Format 'yyyy-MM-dd HH:mm'); Ids = $currentIds }
    $snapFile = Join-Path $histDir ("scan_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $snapshot | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $snapFile -Encoding UTF8
    # Giữ tối đa 12 bản gần nhất
    Get-ChildItem -LiteralPath $histDir -Filter 'scan_*.json' | Sort-Object Name -Descending |
        Select-Object -Skip 12 | Remove-Item -Force -ErrorAction SilentlyContinue
}

function Add-Finding {
    param(
        [string]$Category, [string]$Name, [string]$Target, [string]$Detail,
        [string]$Severity = 'High', [double]$SizeMB = 0,
        [string]$RemoveKind = 'None', [hashtable]$RemoveData = $null
    )
    $script:findings.Add([PSCustomObject]@{
        Category = $Category; Severity = $Severity; Name = $Name
        Target = $Target; Detail = $Detail; SizeMB = $SizeMB
        RemoveKind = $RemoveKind; RemoveData = $RemoveData
    })
}

# ════════════════════════ 18 MODULE QUÉT ════════════════════════

function Invoke-ScanPath {
    foreach ($scope in 'Machine', 'User') {
        $subKey = if ($scope -eq 'Machine') { 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' } else { 'Environment' }
        $hive = if ($scope -eq 'Machine') { 'HKLM' } else { 'HKCU' }
        $rawPath = Get-RawRegValue -Hive $hive -SubKey $subKey -ValueName 'Path'
        if ([string]::IsNullOrEmpty($rawPath)) { continue }
        $seen = @{}
        $pos = 0
        foreach ($entry in ($rawPath -split ';')) {
            $pos++
            $rd = @{ Scope = $scope; Position = $pos }
            if ([string]::IsNullOrWhiteSpace($entry)) {
                Add-Finding -Category 'Path' -Name "$scope #$pos" -Target '<rỗng>' -Detail 'Mục rỗng (thừa dấu ;)' -RemoveKind 'PathEntry' -RemoveData $rd
                continue
            }
            $expanded = [Environment]::ExpandEnvironmentVariables($entry.Trim().Trim('"'))
            $norm = $expanded.TrimEnd('\', '/').ToLowerInvariant()
            if ($seen.ContainsKey($norm)) {
                Add-Finding -Category 'Path' -Name "$scope #$pos" -Target $entry.Trim() -Detail "Trùng lặp với mục #$($seen[$norm])" -RemoveKind 'PathEntry' -RemoveData $rd
            } else { $seen[$norm] = $pos }
            if (-not (Test-Path -LiteralPath $expanded)) {
                Add-Finding -Category 'Path' -Name "$scope #$pos" -Target $entry.Trim() -Detail 'Thư mục không tồn tại' -RemoveKind 'PathEntry' -RemoveData $rd
            }
        }
    }
}

function Invoke-ScanEnvVars {
    foreach ($loc in @(
        @{ Scope = 'Machine'; Hive = 'HKLM'; SubKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' },
        @{ Scope = 'User';    Hive = 'HKCU'; SubKey = 'Environment' })) {
        $root = if ($loc.Hive -eq 'HKLM') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
        $key = $root.OpenSubKey($loc.SubKey)
        if ($null -eq $key) { continue }
        try {
            foreach ($name in $key.GetValueNames()) {
                if ($name -in 'Path', 'PATHEXT', 'PSModulePath', 'OS', 'TEMP', 'TMP') { continue }
                $value = [string]$key.GetValue($name)
                if ($value -notmatch '^[A-Za-z]:\\' -or $value.Contains(';')) { continue }
                $expanded = [Environment]::ExpandEnvironmentVariables($value)
                if (-not (Test-Path -LiteralPath $expanded)) {
                    Add-Finding -Category 'EnvVars' -Name "$($loc.Scope): $name" -Target $value -Detail 'Biến trỏ vào đường dẫn không tồn tại' `
                        -RemoveKind 'RegValue' -RemoveData @{ PSPath = ("{0}:\{1}" -f $loc.Hive, $loc.SubKey); Value = $name }
                }
            }
        } finally { $key.Close() }
    }
}

function Invoke-ScanFolders {
    param([int]$StaleDays = 90, [double]$MinSizeMB = 5)
    $systemFolders = @(
        'Microsoft', 'Windows', 'Packages', 'Temp', 'Programs', 'Comms',
        'ConnectedDevicesPlatform', 'D3DSCache', 'PeerDistRepub', 'Publishers',
        'USOShared', 'USOPrivate', 'SoftwareDistribution', 'Package Cache',
        'PlaceholderTileLogoFolder', 'regid.1991-06.com.microsoft', 'ssh',
        'WindowsHolographicDevices', 'Application Data', 'Documents',
        'Start Menu', 'Desktop', 'Templates', 'CanonicalGroupLimited',
        'PackageManagement', 'GroupPolicy', 'dotnet', 'IsolatedStorage',
        'AMD', 'NVIDIA', 'NVIDIA Corporation', 'Intel', 'InstallShield'
    )
    $fp = Get-AppFingerprint
    $scanRoots = [System.Collections.Generic.List[object]]::new()
    $scanRoots.Add(@{ Label = 'Roaming';       Path = $env:APPDATA })
    $scanRoots.Add(@{ Label = 'Local';         Path = $env:LOCALAPPDATA })
    $scanRoots.Add(@{ Label = 'LocalLow';      Path = (Join-Path (Split-Path $env:LOCALAPPDATA -Parent) 'LocalLow') })
    $scanRoots.Add(@{ Label = 'LocalPrograms'; Path = (Join-Path $env:LOCALAPPDATA 'Programs') })
    $scanRoots.Add(@{ Label = 'ProgramData';   Path = $env:ProgramData })
    # Multi-user (admin đã duyệt): quét thêm AppData của từng user khác
    foreach ($up in $script:otherUserProfiles) {
        $scanRoots.Add(@{ Label = "[$($up.Name)] Roaming";       Path = (Join-Path $up.Path 'AppData\Roaming') })
        $scanRoots.Add(@{ Label = "[$($up.Name)] Local";         Path = (Join-Path $up.Path 'AppData\Local') })
        $scanRoots.Add(@{ Label = "[$($up.Name)] LocalLow";      Path = (Join-Path $up.Path 'AppData\LocalLow') })
        $scanRoots.Add(@{ Label = "[$($up.Name)] LocalPrograms"; Path = (Join-Path $up.Path 'AppData\Local\Programs') })
    }
    $staleCutoff = (Get-Date).AddDays(-$StaleDays)
    foreach ($rootInfo in $scanRoots) {
        if (-not (Test-Path -LiteralPath $rootInfo.Path)) { continue }
        $folders = @(Get-ChildItem -LiteralPath $rootInfo.Path -Directory -ErrorAction SilentlyContinue)
        $fi = 0
        foreach ($folder in $folders) {
            $fi++
            # Cập nhật text cho spinner nền (không tự ghi console -> không tranh chấp)
            if ($script:scanStatus) {
                $script:scanStatus.Text = ('{0} › {1} ({2}/{3}): {4}' -f $script:scanStatus.Prefix, $rootInfo.Label, $fi, $folders.Count, $folder.Name)
            }
            if ($systemFolders -contains $folder.Name) { continue }
            if ($rootInfo.Label.EndsWith('Local') -and $folder.Name -eq 'Programs') { continue }

            $folderLower = $folder.FullName.TrimEnd('\').ToLowerInvariant()
            $matched = $false
            foreach ($loc in $fp.Locations) {
                if ($loc -eq $folderLower -or $loc.StartsWith("$folderLower\") -or $folderLower.StartsWith("$loc\")) { $matched = $true; break }
            }
            if (-not $matched) { $matched = Test-NameMatchesInstalledApp -Name $folder.Name }
            if ($matched) { continue }

            $files = @(Get-ChildItem -LiteralPath $folder.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)
            if ($files.Count -eq 0) {
                Add-Finding -Category 'Folders' -Name $folder.Name -Target $folder.FullName -Detail 'Thư mục rỗng hoàn toàn' -Severity 'Info' `
                    -RemoveKind 'RecycleDir' -RemoveData @{ Path = $folder.FullName }
                continue
            }
            $sizeMB = [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 1)
            if ($sizeMB -lt $MinSizeMB) { continue }
            $lastUsed = $folder.LastWriteTime
            foreach ($f in $files) {
                if ($f.LastWriteTime -gt $lastUsed) { $lastUsed = $f.LastWriteTime }
                if ($f.LastAccessTime -gt $lastUsed) { $lastUsed = $f.LastAccessTime }
            }
            if ($lastUsed -lt $staleCutoff) {
                Add-Finding -Category 'Folders' -Name $folder.Name -Target $folder.FullName `
                    -Detail ("Không khớp app nào; không dùng từ {0}" -f $lastUsed.ToString('yyyy-MM-dd')) -Severity 'Medium' -SizeMB $sizeMB `
                    -RemoveKind 'RecycleDir' -RemoveData @{ Path = $folder.FullName }
            }
        }
    }
}

function Invoke-ScanServices {
    foreach ($svc in (Get-CimInstance Win32_Service -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($svc.PathName)) { continue }
        $exe = Resolve-CommandPath -CommandLine $svc.PathName
        if ($exe -and (Test-ExeMissing -ExePath $exe)) {
            Add-Finding -Category 'Services' -Name $svc.Name -Target $exe `
                -Detail ("File service đã mất ({0} / {1})" -f $svc.StartMode, $svc.State) `
                -RemoveKind 'Service' -RemoveData @{ Name = $svc.Name }
        }
    }
}

function Invoke-ScanStartup {
    $runKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    )
    foreach ($key in $runKeys) {
        if (-not (Test-Path $key)) { continue }
        $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -in 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') { continue }
            $exe = Resolve-CommandPath -CommandLine ([string]$prop.Value)
            if ($exe -and (Test-ExeMissing -ExePath $exe)) {
                Add-Finding -Category 'Startup' -Name $prop.Name -Target $exe -Detail "Run-key tại $key" `
                    -RemoveKind 'RegValue' -RemoveData @{ PSPath = $key; Value = $prop.Name }
            }
        }
    }
    # Multi-user: Run/RunOnce của các user KHÁC
    foreach ($up in $script:otherUserProfiles) {
        if ($up.Loaded) {
            # User đang đăng nhập: hive có sẵn trong HKEY_USERS
            foreach ($suffix in 'Run', 'RunOnce') {
                $hkuKey = "Registry::HKEY_USERS\$($up.Sid)\SOFTWARE\Microsoft\Windows\CurrentVersion\$suffix"
                if (-not (Test-Path $hkuKey)) { continue }
                $props = Get-ItemProperty -Path $hkuKey -ErrorAction SilentlyContinue
                foreach ($prop in $props.PSObject.Properties) {
                    if ($prop.Name -in 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider') { continue }
                    $exe = Resolve-CommandPath -CommandLine ([string]$prop.Value)
                    if ($exe -and (Test-ExeMissing -ExePath $exe)) {
                        Add-Finding -Category 'Startup' -Name ("[{0}] {1}" -f $up.Name, $prop.Name) -Target $exe `
                            -Detail "Run-key của user $($up.Name)" `
                            -RemoveKind 'RegValue' -RemoveData @{ PSPath = $hkuKey; Value = $prop.Name }
                    }
                }
            }
        } else {
            # User OFFLINE: nạp tạm NTUSER.DAT (reg load), đọc xong NHẢ NGAY.
            # Hive đang bị khóa (user vừa đăng nhập / process giữ) -> bỏ qua êm.
            $entries = Read-OfflineRunKeys -ProfilePath $up.Path
            foreach ($entry in $entries) {
                $exe = Resolve-CommandPath -CommandLine $entry.Command
                if ($exe -and (Test-ExeMissing -ExePath $exe)) {
                    Add-Finding -Category 'Startup' -Name ("[{0}] {1}" -f $up.Name, $entry.Value) -Target $exe `
                        -Detail ("Run-key của user {0} (hive offline)" -f $up.Name) `
                        -RemoveKind 'OfflineRegValue' `
                        -RemoveData @{ Hive = (Join-Path $up.Path 'NTUSER.DAT'); SubKey = $entry.SubKey; Value = $entry.Value }
                }
            }
        }
    }

    $shell = New-Object -ComObject WScript.Shell
    $startupDirs = [System.Collections.Generic.List[string]]::new()
    $startupDirs.Add([Environment]::GetFolderPath('Startup'))
    $startupDirs.Add([Environment]::GetFolderPath('CommonStartup'))
    foreach ($up in $script:otherUserProfiles) {
        $startupDirs.Add((Join-Path $up.Path 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'))
    }
    foreach ($dir in $startupDirs) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($item in (Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue)) {
            if ($item.Extension -ne '.lnk') { continue }
            try {
                $target = $shell.CreateShortcut($item.FullName).TargetPath
                if ($target -and (Test-ExeMissing -ExePath $target)) {
                    Add-Finding -Category 'Startup' -Name $item.Name -Target $target -Detail "Shortcut startup tại $dir" `
                        -RemoveKind 'RecycleFile' -RemoveData @{ Path = $item.FullName }
                }
            } catch {}
        }
    }
}

function Invoke-ScanTasks {
    foreach ($task in (Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        foreach ($taskAction in $task.Actions) {
            if (-not ($taskAction.PSObject.Properties.Name -contains 'Execute')) { continue }
            if ([string]::IsNullOrWhiteSpace($taskAction.Execute)) { continue }
            $exec = [Environment]::ExpandEnvironmentVariables($taskAction.Execute.Trim('"'))
            if ($exec -notmatch '^[A-Za-z]:\\') { continue }
            if (Test-ExeMissing -ExePath $exec) {
                Add-Finding -Category 'Tasks' -Name ($task.TaskPath + $task.TaskName) -Target $exec `
                    -Detail ("State: {0}" -f $task.State) `
                    -RemoveKind 'Task' -RemoveData @{ TaskPath = $task.TaskPath; TaskName = $task.TaskName }
            }
        }
    }
}

function Invoke-ScanUninstall {
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($app in (Get-ItemProperty $uninstallPaths -ErrorAction SilentlyContinue)) {
        if (-not $app.DisplayName -or -not $app.UninstallString) { continue }
        if ($app.UninstallString -match 'msiexec') { continue }
        $exe = Resolve-CommandPath -CommandLine $app.UninstallString
        if ($exe -and (Test-ExeMissing -ExePath $exe)) {
            $psPath = $app.PSPath -replace '^Microsoft\.PowerShell\.Core\\', ''
            Add-Finding -Category 'Uninstall' -Name $app.DisplayName -Target $exe `
                -Detail 'Uninstaller đã mất - mục ma trong Add/Remove Programs' `
                -RemoveKind 'RegKey' -RemoveData @{ PSPath = $psPath }
        }
    }
}

function Invoke-ScanAppPaths {
    # Gộp các bản "song sinh" giữa view 64-bit và WOW6432Node (nhiều key App Paths
    # là bản chiếu của nhau - xóa bản này bản kia biến mất theo): mỗi cặp
    # (tên key + exe đích) chỉ ra MỘT finding, khi xóa sẽ quét cả các view
    $merged = [ordered]@{}
    foreach ($base in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths')) {
        if (-not (Test-Path $base)) { continue }
        foreach ($sub in (Get-ChildItem -Path $base -ErrorAction SilentlyContinue)) {
            $default = ($sub | Get-ItemProperty -ErrorAction SilentlyContinue).'(default)'
            if ([string]::IsNullOrWhiteSpace($default)) { continue }
            $exe = [Environment]::ExpandEnvironmentVariables($default.Trim('"'))
            if ($exe -match '^[A-Za-z]:\\' -and (Test-ExeMissing -ExePath $exe)) {
                $mergeKey = '{0}|{1}' -f $sub.PSChildName.ToLowerInvariant(), $exe.ToLowerInvariant()
                if (-not $merged.Contains($mergeKey)) {
                    $merged[$mergeKey] = @{
                        Name  = $sub.PSChildName
                        Target = $exe
                        Paths = [System.Collections.Generic.List[string]]::new()
                    }
                }
                $merged[$mergeKey].Paths.Add((Join-Path $base $sub.PSChildName))
            }
        }
    }
    foreach ($m in $merged.Values) {
        Add-Finding -Category 'AppPaths' -Name $m.Name -Target $m.Target `
            -Detail ("App Path chết ({0} view registry)" -f $m.Paths.Count) `
            -RemoveKind 'RegKeyMulti' -RemoveData @{ Paths = $m.Paths.ToArray() }
    }
}

function Invoke-ScanShortcuts {
    $shell = New-Object -ComObject WScript.Shell
    $dirs = [System.Collections.Generic.List[string]]::new()
    $dirs.Add([Environment]::GetFolderPath('StartMenu'))
    $dirs.Add([Environment]::GetFolderPath('CommonStartMenu'))
    $dirs.Add([Environment]::GetFolderPath('Desktop'))
    $dirs.Add([Environment]::GetFolderPath('CommonDesktopDirectory'))
    # Multi-user: Start Menu + Desktop của các user khác
    foreach ($up in $script:otherUserProfiles) {
        $dirs.Add((Join-Path $up.Path 'AppData\Roaming\Microsoft\Windows\Start Menu'))
        $dirs.Add((Join-Path $up.Path 'Desktop'))
    }
    foreach ($dir in ($dirs | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($lnkFile in (Get-ChildItem -LiteralPath $dir -Recurse -Filter '*.lnk' -File -ErrorAction SilentlyContinue)) {
            try {
                $target = $shell.CreateShortcut($lnkFile.FullName).TargetPath
                if ([string]::IsNullOrWhiteSpace($target)) { continue }
                if ($target -notmatch '^[A-Za-z]:\\') { continue }
                if ((Test-ExeMissing -ExePath $target) -and -not (Test-Path -LiteralPath $target -PathType Container)) {
                    Add-Finding -Category 'Shortcuts' -Name $lnkFile.Name -Target $target `
                        -Detail ("Shortcut chết tại {0}" -f $lnkFile.DirectoryName) -Severity 'Medium' `
                        -RemoveKind 'RecycleFile' -RemoveData @{ Path = $lnkFile.FullName }
                }
            } catch {}
        }
    }
}

function Invoke-ScanFirewall {
    try {
        $filters = Get-NetFirewallApplicationFilter -ErrorAction Stop |
            Where-Object { $_.Program -and $_.Program -ne 'Any' -and $_.Program -notmatch '^System$' }
        $checked = @{}
        foreach ($f in $filters) {
            $exe = [Environment]::ExpandEnvironmentVariables($f.Program)
            if ($exe -notmatch '^[A-Za-z]:\\') { continue }
            $exeKey = $exe.ToLowerInvariant()
            if ($checked.ContainsKey($exeKey)) {
                if (-not $checked[$exeKey]) { continue }
            } else {
                $checked[$exeKey] = Test-ExeMissing -ExePath $exe
                if (-not $checked[$exeKey]) { continue }
            }
            $rule = $f | Get-NetFirewallRule -ErrorAction SilentlyContinue
            $ruleName = if ($rule) { $rule.DisplayName } else { $f.InstanceID }
            $ruleId = if ($rule) { $rule.Name } else { $f.InstanceID }
            Add-Finding -Category 'Firewall' -Name $ruleName -Target $exe -Detail 'Rule cho chương trình đã mất' -Severity 'Info' `
                -RemoveKind 'Firewall' -RemoveData @{ RuleName = $ruleId }
        }
    } catch {
        Write-Warning "Không quét được firewall: $($_.Exception.Message)"
    }
}

function Invoke-ScanDefender {
    try { $pref = Get-MpPreference -ErrorAction Stop } catch { return }
    foreach ($path in @($pref.ExclusionPath)) {
        if ([string]::IsNullOrWhiteSpace($path) -or $path -like 'N/A*') { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($path)
        if (-not (Test-Path -LiteralPath $expanded)) {
            Add-Finding -Category 'Defender' -Name 'ExclusionPath mồ côi' -Target $path `
                -Detail 'Exclusion trỏ đường dẫn không tồn tại - vùng mù antivirus vô nghĩa' -Severity 'Medium' `
                -RemoveKind 'DefenderPath' -RemoveData @{ Value = $path }
        }
    }
    foreach ($proc in @($pref.ExclusionProcess)) {
        if ([string]::IsNullOrWhiteSpace($proc) -or $proc -like 'N/A*') { continue }
        $expanded = [Environment]::ExpandEnvironmentVariables($proc)
        if ($expanded -match '^[A-Za-z]:\\' -and (Test-ExeMissing -ExePath $expanded)) {
            Add-Finding -Category 'Defender' -Name 'ExclusionProcess mồ côi' -Target $proc `
                -Detail 'Process exclusion cho exe không còn' -Severity 'Medium' `
                -RemoveKind 'DefenderProcess' -RemoveData @{ Value = $proc }
        }
    }
    if (@($pref.ExclusionPath) -like 'N/A*') {
        Write-Warning 'Defender ẩn exclusions với non-admin - chạy admin để quét đầy đủ.'
    }
}

function Invoke-ScanCerts {
    $toolCaPatterns = @('PortSwigger', 'Burp', 'Fiddler', 'Charles', 'mitmproxy', 'Proxyman',
                        'NetFilter', 'AdGuard', 'HTTP Toolkit', 'OWASP Zed', 'ZAP')
    $publicCAs = 'Microsoft|Windows|DigiCert|GlobalSign|VeriSign|Sectigo|COMODO|Comodo|Entrust|Go Daddy|GoDaddy|Starfield|thawte|Thawte|Baltimore|USERTRUST|USERTrust|UTN-|QuoVadis|ISRG|SSL Corporation|SSL\.com|Certum|Unizeto|Buypass|IdenTrust|Actalis|SECOM|StartCom|AddTrust|AAA Certificate|Hellenic|Amazon|Digital Signature Trust|SecureTrust|Symantec|GeoTrust|Telia|Trustwave|XRamp|DST Root'
    foreach ($storePath in 'Cert:\CurrentUser\Root', 'Cert:\LocalMachine\Root') {
        foreach ($cert in (Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue)) {
            $subject = [string]$cert.Subject
            $matchedTool = $null
            foreach ($pat in $toolCaPatterns) {
                if ($subject -match [regex]::Escape($pat)) { $matchedTool = $pat; break }
            }
            if ($matchedTool) {
                Add-Finding -Category 'Certs' -Name ("Root CA của tool: {0}" -f $matchedTool) `
                    -Target ("{0} (hết hạn {1})" -f $subject, $cert.NotAfter.ToString('yyyy-MM-dd')) `
                    -Detail ("Store: {0} | Thumbprint: {1} - nếu đã gỡ tool, xóa bằng certmgr.msc (không tự động)" -f $storePath, $cert.Thumbprint) -Severity 'Medium'
            }
            elseif ($storePath -eq 'Cert:\CurrentUser\Root' -and $cert.Subject -eq $cert.Issuer -and $subject -notmatch $publicCAs) {
                Add-Finding -Category 'Certs' -Name 'Root CA tự ký bất thường (store user)' `
                    -Target ("{0} (hết hạn {1})" -f $subject, $cert.NotAfter.ToString('yyyy-MM-dd')) `
                    -Detail ("Thumbprint: {0} - xác minh có chủ đích không (dev cert do dotnet/IIS tạo là bình thường)" -f $cert.Thumbprint) -Severity 'Info'
            }
        }
    }
}

function Invoke-ScanIFEO {
    $base = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options')
    if ($null -eq $base) { return }
    try {
        foreach ($subName in $base.GetSubKeyNames()) {
            $sub = $base.OpenSubKey($subName)
            if ($null -eq $sub) { continue }
            try {
                $debugger = [string]$sub.GetValue('Debugger')
                if ([string]::IsNullOrWhiteSpace($debugger)) { continue }
                $exe = Resolve-CommandPath -CommandLine $debugger
                $psPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$subName"
                if ($exe -and (Test-ExeMissing -ExePath $exe)) {
                    Add-Finding -Category 'IFEO' -Name $subName -Target $debugger `
                        -Detail 'Debugger hijack trỏ exe đã mất - tàn dư hoặc dấu vết malware cũ' `
                        -RemoveKind 'RegValue' -RemoveData @{ PSPath = $psPath; Value = 'Debugger' }
                } else {
                    Add-Finding -Category 'IFEO' -Name $subName -Target $debugger `
                        -Detail 'Debugger đang gắn - xác minh là chủ đích (vd: vsjitdebugger)' -Severity 'Info'
                }
            } finally { $sub.Close() }
        }
    } finally { $base.Close() }
}

function Invoke-ScanNativeMsg {
    $bases = @(
        'HKCU:\SOFTWARE\Google\Chrome\NativeMessagingHosts',
        'HKLM:\SOFTWARE\Google\Chrome\NativeMessagingHosts',
        'HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\NativeMessagingHosts',
        'HKCU:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts',
        'HKLM:\SOFTWARE\Microsoft\Edge\NativeMessagingHosts',
        'HKCU:\SOFTWARE\Mozilla\NativeMessagingHosts',
        'HKLM:\SOFTWARE\Mozilla\NativeMessagingHosts'
    )
    foreach ($base in $bases) {
        if (-not (Test-Path $base)) { continue }
        foreach ($sub in (Get-ChildItem -Path $base -ErrorAction SilentlyContinue)) {
            $manifest = ($sub | Get-ItemProperty -ErrorAction SilentlyContinue).'(default)'
            if ([string]::IsNullOrWhiteSpace($manifest)) { continue }
            $manifest = [Environment]::ExpandEnvironmentVariables($manifest.Trim('"'))
            $keyPath = Join-Path $base $sub.PSChildName
            if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
                Add-Finding -Category 'NativeMsg' -Name $sub.PSChildName -Target $manifest `
                    -Detail "Manifest JSON đã mất - đăng ký tại $base" `
                    -RemoveKind 'RegKey' -RemoveData @{ PSPath = $keyPath }
                continue
            }
            try {
                $json = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
                if ($json.path) {
                    $exePath = [string]$json.path
                    if ($exePath -notmatch '^[A-Za-z]:\\') { $exePath = Join-Path (Split-Path $manifest -Parent) $exePath }
                    if (Test-ExeMissing -ExePath $exePath) {
                        Add-Finding -Category 'NativeMsg' -Name $sub.PSChildName -Target $exePath `
                            -Detail "Exe trong manifest đã mất - đăng ký tại $base" `
                            -RemoveKind 'RegKey' -RemoveData @{ PSPath = $keyPath }
                    }
                }
            } catch {}
        }
    }
}

function Invoke-ScanProtocols {
    $classesRoot = [Microsoft.Win32.Registry]::ClassesRoot
    foreach ($name in $classesRoot.GetSubKeyNames()) {
        if ($name.StartsWith('.')) { continue }
        $key = $classesRoot.OpenSubKey($name)
        if ($null -eq $key) { continue }
        try {
            if ($null -eq $key.GetValue('URL Protocol', $null)) { continue }
            $cmdKey = $key.OpenSubKey('shell\open\command')
            if ($null -eq $cmdKey) { continue }
            try {
                $command = [string]$cmdKey.GetValue('')
                if ([string]::IsNullOrWhiteSpace($command)) { continue }
                $exe = Resolve-CommandPath -CommandLine $command
                if ($exe -and $exe -match '^[A-Za-z]:\\' -and (Test-ExeMissing -ExePath $exe)) {
                    # HKCR là VIEW GỘP của HKCU+HKLM Classes - phải xóa ở hive thật,
                    # xóa qua HKCR sẽ vỡ giữa chừng ("subkey does not exist")
                    Add-Finding -Category 'Protocols' -Name "$name`://" -Target $exe `
                        -Detail 'Protocol handler trỏ exe đã mất' `
                        -RemoveKind 'ProtocolKey' -RemoveData @{ Name = $name }
                }
            } finally { $cmdKey.Close() }
        } finally { $key.Close() }
    }
}

function Invoke-ScanVendorReg {
    $skipKeys = @(
        'Microsoft', 'Classes', 'Policies', 'WOW6432Node', 'Clients', 'RegisteredApplications',
        'ODBC', 'OpenSSH', 'Intel', 'AMD', 'NVIDIA Corporation', 'Wow6432Node', 'GNU',
        'Windows', 'WindowsNT', 'Netscape', 'Mozilla', 'MozillaPlugins', 'mozilla.org',
        'Google', 'Chromium', 'Python', 'JavaSoft', 'Khronos', 'OEM', 'Partner', 'Realtek',
        'Synaptics', 'Waves Audio', 'DTS', 'Dolby', 'ASUS', 'Dell', 'HP', 'Lenovo', 'MSI'
    )
    foreach ($rootInfo in @(
        @{ Label = 'HKCU'; Key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('SOFTWARE') },
        @{ Label = 'HKLM'; Key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE') })) {
        $root = $rootInfo.Key
        if ($null -eq $root) { continue }
        try {
            foreach ($name in $root.GetSubKeyNames()) {
                if ($skipKeys -contains $name) { continue }
                if (Test-NameMatchesInstalledApp -Name $name) { continue }
                $sub = $root.OpenSubKey($name)
                if ($null -eq $sub) { continue }
                try { $subCount = $sub.SubKeyCount; $valCount = $sub.ValueCount } finally { $sub.Close() }
                $sev = if ($subCount -eq 0 -and $valCount -eq 0) { 'Info' } else { 'Medium' }
                Add-Finding -Category 'VendorReg' -Name $name -Target ("{0}\Software\{1}" -f $rootInfo.Label, $name) `
                    -Detail ("Không khớp app nào đang cài ({0} subkey, {1} value)" -f $subCount, $valCount) -Severity $sev `
                    -RemoveKind 'RegKey' -RemoveData @{ PSPath = ("{0}:\SOFTWARE\{1}" -f $rootInfo.Label, $name) }
            }
        } finally { $root.Close() }
    }
}

function Invoke-ScanDocker {
    # Tàn dư Docker Desktop/CLI. Còn cài -> chỉ báo kho dữ liệu lớn + lệnh dọn chính chủ
    # (Info, không cho xóa - giống DevTrash); đã gỡ -> thư mục dữ liệu và đăng ký WSL
    # distro docker-desktop* là tàn dư. Service com.docker.service mất binary đã có
    # module Services bắt, không lặp lại ở đây.
    # Service docker/com.docker.service với binary CÒN SỐNG = Docker Engine đang cài
    # (kể cả không có Desktop lẫn CLI trên PATH - ProgramData\Docker khi đó chứa image
    # đang dùng, tuyệt đối không được coi là tàn dư); binary mất thì module Services
    # đã bắt service, ở đây vẫn tính là "đã gỡ" để báo thư mục sót.
    $svcAlive = $false
    foreach ($s in @(Get-CimInstance Win32_Service -Filter "Name='docker' OR Name='com.docker.service'" -ErrorAction SilentlyContinue)) {
        $exe = Resolve-CommandPath -CommandLine $s.PathName
        if ($exe -and -not (Test-ExeMissing -ExePath $exe)) { $svcAlive = $true }
    }
    $dockerInstalled = $svcAlive -or
                       (Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe')) -or
                       (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Programs\Docker\Docker\Docker Desktop.exe')) -or
                       (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker Desktop') -or
                       (Test-Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Docker Desktop') -or
                       ($null -ne (Get-Command docker -ErrorAction SilentlyContinue))
    $dataDirs = @(
        (Join-Path $env:APPDATA 'Docker'),
        (Join-Path $env:APPDATA 'Docker Desktop'),
        (Join-Path $env:LOCALAPPDATA 'Docker'),
        (Join-Path $env:LOCALAPPDATA 'DockerDesktop'),
        (Join-Path $env:ProgramData 'Docker'),
        (Join-Path $env:ProgramData 'DockerDesktop'),
        (Join-Path $env:USERPROFILE '.docker')
    )
    if ($dockerInstalled) {
        # Đang cài: chỉ nhắc kho >= 1 GB (image/cache/vhdx) để dọn bằng lệnh chính chủ
        foreach ($dir in $dataDirs) {
            $size = Get-DirSizeMB -Path $dir
            if ($size -lt 1024) { continue }
            Add-Finding -Category 'Docker' -Name 'Kho dữ liệu Docker (đang cài)' -Target $dir -SizeMB $size `
                -Detail 'Docker còn cài - KHÔNG xóa tay; dọn image/cache bằng: docker system prune (thêm -a nếu muốn xóa cả image chưa dùng)' `
                -Severity 'Info'
        }
        return
    }
    foreach ($dir in $dataDirs) {
        $size = Get-DirSizeMB -Path $dir
        if ($size -lt 0) { continue }
        Add-Finding -Category 'Docker' -Name (Split-Path $dir -Leaf) -Target $dir -SizeMB $size `
            -Detail 'Docker đã gỡ nhưng thư mục dữ liệu còn lại - tàn dư, xóa an toàn' -Severity 'High' `
            -RemoveKind 'RecycleDir' -RemoveData @{ Path = $dir }
    }
    # Thư mục cài đặt sót trong Program Files (exe chính đã mất nhưng folder còn)
    $installDir = Join-Path $env:ProgramFiles 'Docker'
    if (Test-Path -LiteralPath $installDir) {
        Add-Finding -Category 'Docker' -Name 'Docker (Program Files)' -Target $installDir `
            -SizeMB (Get-DirSizeMB -Path $installDir) `
            -Detail 'Thư mục cài đặt còn sót sau khi gỡ Docker Desktop' -Severity 'High' `
            -RemoveKind 'RecycleDir' -RemoveData @{ Path = $installDir }
    }
    # Đăng ký WSL distro docker-desktop* mồ côi (vhdx dữ liệu nằm trong LOCALAPPDATA\Docker
    # đã báo ở trên - xóa key đăng ký tương đương wsl --unregister)
    $lxss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
    if (Test-Path $lxss) {
        foreach ($key in (Get-ChildItem -Path $lxss -ErrorAction SilentlyContinue)) {
            $name = [string](Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue).DistributionName
            if ($name -notmatch '^docker-desktop') { continue }
            Add-Finding -Category 'Docker' -Name ("WSL distro: {0}" -f $name) -Target ($lxss + '\' + $key.PSChildName) `
                -Detail ("Đăng ký WSL distro của Docker Desktop đã gỡ (gỡ chuẩn: wsl --unregister {0} - xóa key này tương đương)" -f $name) `
                -Severity 'High' -RemoveKind 'RegKey' -RemoveData @{ PSPath = ($lxss + '\' + $key.PSChildName) }
        }
    }
}

function Invoke-ScanWSL {
    # Tàn dư WSL: đăng ký distro trỏ thư mục đã mất, dữ liệu distro (ext4.vhdx - có thể
    # nhiều GB) không còn đăng ký, thư mục lxss legacy (WSL1 trước 1709). Distro đăng ký
    # hợp lệ KHÔNG bị đụng tới. Distro docker-desktop* nhường module Docker xử lý.
    $lxss = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss'
    $registered = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $lxss) {
        foreach ($key in (Get-ChildItem -Path $lxss -ErrorAction SilentlyContinue)) {
            if ($key.PSChildName -notmatch '^\{[0-9A-Fa-f-]+\}$') { continue }   # distro luôn là subkey GUID
            $props = Get-ItemProperty -Path $key.PSPath -ErrorAction SilentlyContinue
            $name = [string]$props.DistributionName
            if ($name -match '^docker-desktop') { continue }
            $base = ([string]$props.BasePath) -replace '^\\\\\?\\', ''   # bỏ prefix \\?\ của distro mới
            if ([string]::IsNullOrWhiteSpace($base)) { continue }
            if (Test-Path -LiteralPath $base) {
                $registered.Add($base.TrimEnd('\').ToLowerInvariant())
            } else {
                Add-Finding -Category 'WSL' -Name ("Distro mồ côi: {0}" -f $name) -Target $base `
                    -Detail 'Đăng ký trong Lxss nhưng thư mục dữ liệu đã mất - distro hỏng, wsl không khởi động được nó nữa' `
                    -RemoveKind 'RegKey' -RemoveData @{ PSPath = ($lxss + '\' + $key.PSChildName) }
            }
        }
    }
    # Dữ liệu distro trên đĩa mà WSL không còn đăng ký (unregister/gỡ sót lại vhdx)
    $candidates = [System.Collections.Generic.List[object]]::new()
    $wslRoot = Join-Path $env:LOCALAPPDATA 'wsl'
    if (Test-Path -LiteralPath $wslRoot) {
        foreach ($dir in (Get-ChildItem -LiteralPath $wslRoot -Directory -ErrorAction SilentlyContinue)) {
            if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'ext4.vhdx'))) { continue }
            if ($registered -contains $dir.FullName.TrimEnd('\').ToLowerInvariant()) { continue }
            $candidates.Add(@{ Remove = $dir.FullName; Pkg = $null })
        }
    }
    $pkgRoot = Join-Path $env:LOCALAPPDATA 'Packages'
    if (Test-Path -LiteralPath $pkgRoot) {
        foreach ($pkg in (Get-ChildItem -LiteralPath $pkgRoot -Directory -ErrorAction SilentlyContinue)) {
            $state = Join-Path $pkg.FullName 'LocalState'
            if (-not (Test-Path -LiteralPath (Join-Path $state 'ext4.vhdx'))) { continue }
            if ($registered -contains $state.TrimEnd('\').ToLowerInvariant()) { continue }
            # Gói Store đã gỡ mà còn dữ liệu -> cả thư mục gói là tàn dư
            $candidates.Add(@{ Remove = $pkg.FullName; Pkg = $pkg.Name })
        }
    }
    if ($candidates.Count -gt 0) {
        # Gói Store còn cài thì KHÔNG coi là tàn dư (app còn đó, chạy lại sẽ dùng tiếp);
        # Get-AppxPackage lỗi (service tắt...) -> không xác định được -> bỏ qua nhóm gói cho an toàn
        $families = $null
        if (@($candidates | Where-Object { $_.Pkg }).Count -gt 0) {
            try { $families = @((Get-AppxPackage -ErrorAction Stop).PackageFamilyName) } catch { $families = $null }
        }
        foreach ($c in $candidates) {
            if ($c.Pkg) {
                if ($null -eq $families) { continue }
                if ($families -contains $c.Pkg) { continue }
            }
            Add-Finding -Category 'WSL' -Name 'Dữ liệu distro không còn đăng ký' -Target $c.Remove `
                -SizeMB (Get-DirSizeMB -Path $c.Remove) `
                -Detail 'Có ext4.vhdx nhưng WSL không đăng ký distro nào ở đây (unregister/gỡ sót) - xem kỹ trước khi xóa' `
                -Severity 'Medium' -RemoveKind 'RecycleDir' -RemoveData @{ Path = $c.Remove }
        }
    }
    # Thư mục WSL1 legacy (%LOCALAPPDATA%\lxss - kiến trúc cũ trước Windows 1709)
    $legacy = Join-Path $env:LOCALAPPDATA 'lxss'
    if ((Test-Path -LiteralPath $legacy) -and ($registered -notcontains $legacy.TrimEnd('\').ToLowerInvariant())) {
        Add-Finding -Category 'WSL' -Name 'Thư mục WSL1 legacy (lxss)' -Target $legacy -SizeMB (Get-DirSizeMB -Path $legacy) `
            -Detail 'Kiến trúc WSL1 cũ (trước Windows 1709) - WSL hiện tại không dùng; xem kỹ trước khi xóa' `
            -Severity 'Medium' -RemoveKind 'RecycleDir' -RemoveData @{ Path = $legacy }
    }
}

# ════════════════════════ DEV TRASH (Developer) ════════════════════════

function Invoke-ScanDevTrash {
    param([switch]$AsFindings)
    $toolchains = @(
        @{ Name = 'Node.js / npm';  Command = 'npm';    Caches = @("$env:LOCALAPPDATA\npm-cache"); CleanCmd = 'npm cache clean --force' }
        @{ Name = 'pnpm';           Command = 'pnpm';   Caches = @("$env:LOCALAPPDATA\pnpm-cache", "$env:LOCALAPPDATA\pnpm\store"); CleanCmd = 'pnpm store prune' }
        @{ Name = 'Yarn';           Command = 'yarn';   Caches = @("$env:LOCALAPPDATA\Yarn\Cache"); CleanCmd = 'yarn cache clean' }
        @{ Name = 'Bun';            Command = 'bun';    Caches = @("$env:USERPROFILE\.bun\install\cache"); CleanCmd = 'bun pm cache rm' }
        @{ Name = 'Python / pip';   Command = 'pip';    Caches = @("$env:LOCALAPPDATA\pip\cache"); CleanCmd = 'pip cache purge' }
        @{ Name = '.NET / NuGet';   Command = 'dotnet'; Caches = @("$env:USERPROFILE\.nuget\packages", "$env:LOCALAPPDATA\NuGet"); CleanCmd = 'dotnet nuget locals all --clear' }
        @{ Name = 'Java / Gradle';  Command = 'gradle'; Caches = @("$env:USERPROFILE\.gradle\caches", "$env:USERPROFILE\.gradle\daemon"); CleanCmd = 'gradle --stop rồi xóa .gradle\caches' }
        @{ Name = 'Java / Maven';   Command = 'mvn';    Caches = @("$env:USERPROFILE\.m2\repository"); CleanCmd = 'mvn dependency:purge-local-repository' }
        @{ Name = 'Go';             Command = 'go';     Caches = @("$env:USERPROFILE\go\pkg\mod", "$env:LOCALAPPDATA\go-build"); CleanCmd = 'go clean -modcache; go clean -cache' }
        @{ Name = 'Rust / Cargo';   Command = 'cargo';  Caches = @("$env:USERPROFILE\.cargo\registry", "$env:USERPROFILE\.cargo\git"); CleanCmd = 'cargo cache -a' }
        @{ Name = 'Flutter / Dart'; Command = 'flutter';Caches = @("$env:LOCALAPPDATA\Pub\Cache"); CleanCmd = 'flutter pub cache clean' }
        @{ Name = 'PHP / Composer'; Command = 'composer';Caches = @("$env:LOCALAPPDATA\Composer"); CleanCmd = 'composer clear-cache' }
        @{ Name = 'Playwright';     Command = 'npx';    Caches = @("$env:LOCALAPPDATA\ms-playwright"); CleanCmd = 'npx playwright uninstall --all (cẩn thận)' }
        @{ Name = 'Chocolatey';     Command = 'choco';  Caches = @("$env:TEMP\chocolatey", "$env:ProgramData\ChocolateyHttpCache"); CleanCmd = 'choco cache remove' }
        @{ Name = 'Scoop';          Command = 'scoop';  Caches = @("$env:USERPROFILE\scoop\cache"); CleanCmd = 'scoop cache rm *' }
    )
    $installed = [System.Collections.Generic.List[object]]::new()
    $ti = 0
    foreach ($tc in $toolchains) {
        $ti++
        if ($script:scanStatus) {
            $script:scanStatus.Text = ('{0} › {1} ({2}/{3})' -f $script:scanStatus.Prefix, $tc.Name, $ti, $toolchains.Count)
        } else {
            Write-StatusLine ("  {0} DevTrash ({1}/{2}): {3}" -f (Get-SpinFrame), $ti, $toolchains.Count, $tc.Name)
        }
        $isInstalled = $null -ne (Get-Command $tc.Command -ErrorAction SilentlyContinue)
        $cacheSizeMB = 0.0
        $existing = [System.Collections.Generic.List[object]]::new()
        foreach ($cache in $tc.Caches) {
            $size = Get-DirSizeMB -Path $cache
            if ($size -ge 0) { $cacheSizeMB += $size; $existing.Add(@{ Path = $cache; SizeMB = $size }) }
        }
        if ($existing.Count -eq 0 -and -not $isInstalled) { continue }
        if ($isInstalled) {
            $installed.Add([PSCustomObject]@{ Name = $tc.Name; SizeMB = $cacheSizeMB; Caches = $existing; CleanCmd = $tc.CleanCmd })
        } elseif ($existing.Count -gt 0) {
            foreach ($c in $existing) {
                Add-Finding -Category 'DevTrash' -Name $tc.Name -Target $c.Path -SizeMB $c.SizeMB `
                    -Detail 'Cache của toolchain KHÔNG còn cài - tàn dư, xóa an toàn' -Severity 'High' `
                    -RemoveKind 'RecycleDir' -RemoveData @{ Path = $c.Path }
            }
        }
    }
    # In báo cáo qua cơ chế "nhường" của spinner nền (caller start spinner TRƯỚC khi
    # gọi hàm này, stop ở finally SAU khi return) - in thẳng sẽ bị frame spinner
    # 80ms vẽ đè lên dòng đang in -> báo cáo garbled/lệch cột (xác suất thấp nhưng thật)
    Invoke-WithSpinnerPaused -Handle $script:activeSpinner -Body {
        Write-StatusLine ("√ DevTrash: đã kiểm tra {0} toolchain" -f $toolchains.Count) -Color Green -Persist
        Write-Host ("[ĐANG CÀI] {0} toolchain - dọn bằng lệnh CHÍNH CHỦ (không tự xóa):" -f $installed.Count) -ForegroundColor Cyan
        foreach ($it in ($installed | Sort-Object SizeMB -Descending)) {
            $color = if ($it.SizeMB -gt 1024) { 'Yellow' } else { 'Gray' }
            Write-Host ("  • {0,-18} {1,8:N0} MB   → {2}" -f $it.Name, $it.SizeMB, $it.CleanCmd) -ForegroundColor $color
        }
    }
}

function Test-FindingNeedsAdmin {
    # Ước lượng mục này có cần Administrator để xóa không (để cảnh báo TRƯỚC khi làm)
    param($Finding)
    switch ($Finding.RemoveKind) {
        'Service'         { return $true }
        'Firewall'        { return $true }
        'DefenderPath'    { return $true }
        'DefenderProcess' { return $true }
        'Task'            { return ($Finding.RemoveData.TaskPath -eq '\') }   # task gốc thường của hệ thống
        'PathEntry'       { return ($Finding.RemoveData.Scope -eq 'Machine') }
        'RegValue'        { return ([string]$Finding.RemoveData.PSPath -match '^(HKLM:|Registry::HKEY_LOCAL_MACHINE|Registry::HKEY_USERS)') }
        'RegKey'          { return ([string]$Finding.RemoveData.PSPath -match '^(HKLM:|Registry::HKEY_LOCAL_MACHINE|Registry::HKEY_USERS)') }
        'RegKeyMulti'     { return [bool](@($Finding.RemoveData.Paths) | Where-Object { $_ -match '^(HKLM:|Registry::HKEY_LOCAL_MACHINE|Registry::HKEY_USERS)' }) }
        'ProtocolKey'     { return (Test-Path ("HKLM:\Software\Classes\{0}" -f $Finding.RemoveData.Name)) }
        'OfflineRegValue' { return $true }   # reg load/unload cần Administrator
        'RecycleDir'      {
            $p = [string]$Finding.RemoveData.Path
            return ($p -match '^[A-Za-z]:\\(ProgramData|Program Files)') -or
                   ($p -match '^[A-Za-z]:\\Users\\' -and -not $p.StartsWith($env:USERPROFILE, [System.StringComparison]::OrdinalIgnoreCase))
        }
        'RecycleFile'     {
            $p = [string]$Finding.RemoveData.Path
            return ($p -match '^[A-Za-z]:\\(ProgramData|Program Files)') -or
                   ($p -match '^[A-Za-z]:\\Users\\' -and -not $p.StartsWith($env:USERPROFILE, [System.StringComparison]::OrdinalIgnoreCase))
        }
        default           { return $false }
    }
}

# ════════════════════════ REMOVAL ENGINE ════════════════════════

function Remove-SelectedFindings {
    param([object[]]$Selected, [hashtable]$L)
    Add-Type -AssemblyName Microsoft.VisualBasic
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupDir = Join-Path $PSScriptRoot "WinTrashBackups\$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $log = [System.Collections.Generic.List[string]]::new()
    $ok = 0; $fail = 0
    $isAdmin = Test-IsAdmin
    $pathChanges = @{}   # gom các PathEntry theo scope để xử lý 1 lần

    $idx = 0
    $total = $Selected.Count
    # Spinner nền quay đều suốt quá trình gỡ (mục xóa lâu không làm đứng hình);
    # các dòng kết quả √/× in qua cơ chế "nhường" để không tranh chấp console
    $removalSpinner = Start-ScanSpinner -Text $L.Cleaning
    try {
    foreach ($f in $Selected) {
        $idx++
        if ($removalSpinner) { $removalSpinner.Hash.Text = ('[{0}/{1}] {2}: {3}' -f $idx, $total, $f.Category, $f.Name) }
        $deferOrSkip = $false
        try {
            switch ($f.RemoveKind) {
                'PathEntry' {
                    # LƯU Ý: không dùng 'continue' trong switch (nó không nhảy vòng foreach) - dùng cờ
                    $scope = $f.RemoveData.Scope
                    if (-not $pathChanges.ContainsKey($scope)) { $pathChanges[$scope] = [System.Collections.Generic.List[int]]::new() }
                    $pathChanges[$scope].Add([int]$f.RemoveData.Position)
                    $deferOrSkip = $true   # xử lý gộp ở cuối
                }
                'RecycleDir' {
                    try {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($f.RemoveData.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
                    } catch {
                        # API Recycle Bin dở chứng (vd: "not supported") -> chuyển cả thư mục
                        # vào thư mục backup của lần dọn này (vẫn hoàn tác được)
                        $destDir = Join-Path $backupDir ("dir_{0}_{1}" -f $idx, (Split-Path $f.RemoveData.Path -Leaf))
                        Move-Item -LiteralPath $f.RemoveData.Path -Destination $destDir -Force -ErrorAction Stop
                    }
                    if (Test-Path -LiteralPath $f.RemoveData.Path) { throw 'Thư mục vẫn còn (bị khóa?)' }
                }
                'RecycleFile' {
                    try {
                        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($f.RemoveData.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
                    } catch {
                        # Fallback: copy file vào backup rồi xóa thẳng (fix "not supported" ở ProgramData)
                        $destFile = Join-Path $backupDir ("file_{0}_{1}" -f $idx, (Split-Path $f.RemoveData.Path -Leaf))
                        Copy-Item -LiteralPath $f.RemoveData.Path -Destination $destFile -Force -ErrorAction Stop
                        Remove-Item -LiteralPath $f.RemoveData.Path -Force -ErrorAction Stop
                    }
                }
                'ProtocolKey' {
                    # Xóa ở CẢ HAI hive thật (HKCU + HKLM Software\Classes), backup từng cái
                    $protoName = $f.RemoveData.Name
                    $safeProto = ($protoName -replace '[^\w\.-]', '_')
                    $deletedAny = $false
                    $protoErrors = [System.Collections.Generic.List[string]]::new()
                    foreach ($hivePair in @(
                        @{ PS = "HKCU:\Software\Classes\$protoName"; Reg = "HKEY_CURRENT_USER\Software\Classes\$protoName" },
                        @{ PS = "HKLM:\Software\Classes\$protoName"; Reg = "HKEY_LOCAL_MACHINE\Software\Classes\$protoName" })) {
                        if (-not (Test-Path -Path $hivePair.PS)) { continue }
                        & reg.exe export $hivePair.Reg (Join-Path $backupDir "protocol_$idx`_$safeProto.reg") /y | Out-Null
                        try {
                            Remove-Item -Path $hivePair.PS -Recurse -Force -ErrorAction Stop
                            $deletedAny = $true
                        } catch { $protoErrors.Add($_.Exception.Message) }
                    }
                    if ($protoErrors.Count -gt 0) {
                        if ($deletedAny) { throw ('đã xóa 1 hive, hive còn lại lỗi: ' + ($protoErrors -join '; ')) }
                        throw ($protoErrors -join '; ')
                    }
                    if (-not $deletedAny) { throw 'không tìm thấy key ở hive nào (đã bị xóa trước đó?)' }
                }
                'RegValue' {
                    # Value đã biến mất (bản chiếu WOW64 / đã dọn trước đó) = mục tiêu đạt được -> OK
                    $existing = Get-ItemProperty -Path $f.RemoveData.PSPath -Name $f.RemoveData.Value -ErrorAction SilentlyContinue
                    if ($null -ne $existing) {
                        $regExe = ConvertTo-RegExePath -PSPath $f.RemoveData.PSPath
                        $safe = ($f.Name -replace '[^\w\.-]', '_')
                        & reg.exe export $regExe (Join-Path $backupDir "regval_$idx`_$safe.reg") 2>$null /y | Out-Null
                        Remove-ItemProperty -Path $f.RemoveData.PSPath -Name $f.RemoveData.Value -Force -ErrorAction Stop
                    }
                }
                'RegKey' {
                    # Key đã biến mất = mục tiêu đạt được -> OK, không báo lỗi
                    if (Test-Path -Path $f.RemoveData.PSPath) {
                        $regExe = ConvertTo-RegExePath -PSPath $f.RemoveData.PSPath
                        $safe = ($f.Name -replace '[^\w\.-]', '_')
                        & reg.exe export $regExe (Join-Path $backupDir "regkey_$idx`_$safe.reg") 2>$null /y | Out-Null
                        Remove-Item -Path $f.RemoveData.PSPath -Recurse -Force -ErrorAction Stop
                    }
                }
                'OfflineRegValue' {
                    # Run-key của user offline: nạp hive -> backup -> xóa value -> nhả hive
                    $od = $f.RemoveData
                    $safe = ($f.Name -replace '[^\w\.-]', '_')
                    $offlineResult = Invoke-WithOfflineHive -HivePath $od.Hive -Body {
                        & reg.exe export ("HKEY_USERS\{0}\{1}" -f $script:offlineMount, $od.SubKey) `
                            (Join-Path $backupDir "offline_$idx`_$safe.reg") 2>$null /y | Out-Null
                        $key = [Microsoft.Win32.Registry]::Users.OpenSubKey("$script:offlineMount\$($od.SubKey)", $true)
                        if ($null -eq $key) { return 'notfound' }
                        try { $key.DeleteValue($od.Value, $false) } finally { $key.Close() }
                        return 'ok'
                    }
                    if ($null -eq $offlineResult) { throw 'không nạp được hive (user vừa đăng nhập? thử lại sau)' }
                }
                'RegKeyMulti' {
                    # Một finding đại diện cho cùng key ở nhiều view registry (64-bit + WOW6432Node):
                    # xóa mọi view còn tồn tại; view đã biến mất (bản chiếu) thì bỏ qua êm
                    $safe = ($f.Name -replace '[^\w\.-]', '_')
                    $multiErrors = [System.Collections.Generic.List[string]]::new()
                    foreach ($regPath in @($f.RemoveData.Paths)) {
                        if (-not (Test-Path -Path $regPath)) { continue }
                        $regExe = ConvertTo-RegExePath -PSPath $regPath
                        & reg.exe export $regExe (Join-Path $backupDir "regkey_$idx`_$safe.reg") 2>$null /y | Out-Null
                        try { Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop }
                        catch { $multiErrors.Add($_.Exception.Message) }
                    }
                    if ($multiErrors.Count -gt 0) { throw ($multiErrors -join '; ') }
                }
                'Service' {
                    & reg.exe export ("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\" + $f.RemoveData.Name) (Join-Path $backupDir "service_$($f.RemoveData.Name).reg") /y | Out-Null
                    Stop-Service -Name $f.RemoveData.Name -Force -ErrorAction SilentlyContinue
                    & sc.exe delete $f.RemoveData.Name | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "sc delete mã lỗi $LASTEXITCODE (cần admin?)" }
                }
                'Task' {
                    $safe = ($f.RemoveData.TaskName -replace '[^\w\.-]', '_')
                    Export-ScheduledTask -TaskPath $f.RemoveData.TaskPath -TaskName $f.RemoveData.TaskName -ErrorAction SilentlyContinue |
                        Set-Content -LiteralPath (Join-Path $backupDir "task_$safe.xml") -Encoding Unicode
                    # Manifest để restore đúng TaskPath/TaskName gốc
                    Add-Content -LiteralPath (Join-Path $backupDir 'tasks_manifest.txt') `
                        -Value ("task_$safe.xml|{0}|{1}" -f $f.RemoveData.TaskPath, $f.RemoveData.TaskName) -Encoding UTF8
                    Unregister-ScheduledTask -TaskPath $f.RemoveData.TaskPath -TaskName $f.RemoveData.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                    if (Get-ScheduledTask -TaskPath $f.RemoveData.TaskPath -TaskName $f.RemoveData.TaskName -ErrorAction SilentlyContinue) {
                        throw 'Task vẫn còn (cần admin?)'
                    }
                }
                'Firewall' {
                    Get-NetFirewallRule -Name $f.RemoveData.RuleName -ErrorAction Stop |
                        Out-String | Add-Content -LiteralPath (Join-Path $backupDir 'firewall_rules_info.txt')
                    Remove-NetFirewallRule -Name $f.RemoveData.RuleName -ErrorAction Stop
                }
                'DefenderPath' {
                    if (-not $isAdmin) { throw 'Cần Administrator' }
                    Remove-MpPreference -ExclusionPath $f.RemoveData.Value -ErrorAction Stop
                }
                'DefenderProcess' {
                    if (-not $isAdmin) { throw 'Cần Administrator' }
                    Remove-MpPreference -ExclusionProcess $f.RemoveData.Value -ErrorAction Stop
                }
                default { $deferOrSkip = $true }
            }
            if ($deferOrSkip) { continue }
            # KHÔNG dùng GetNewClosure: nó buộc block vào dynamic module -> khi chạy
            # script kiểu `.\WinTrash.ps1` (hàm nằm ở script scope, không phải global
            # như khi chạy -File) thì module không thấy Write-StatusLine (issue #1).
            # Block thường giữ session state gốc -> hàm lẫn biến đều resolve đúng.
            Invoke-WithSpinnerPaused -Handle $removalSpinner -Body {
                Write-StatusLine ("  √ [{0}/{1}] [{2}] {3}" -f $idx, $total, $f.Category, $f.Name) -Color Green -Persist
            }
            $log.Add("OK   [$($f.Category)] $($f.Name) -> $($f.Target)")
            $ok++
        }
        catch {
            $errMsg = $_.Exception.Message
            Invoke-WithSpinnerPaused -Handle $removalSpinner -Body {
                Write-StatusLine ("  × [{0}/{1}] [{2}] {3} - {4}" -f $idx, $total, $f.Category, $f.Name, $errMsg) -Color Red -Persist
            }
            $log.Add("FAIL [$($f.Category)] $($f.Name) - $errMsg")
            $fail++
        }
    }
    } finally { Stop-ScanSpinner -Handle $removalSpinner }

    # Xử lý gộp các mục PATH (mỗi scope ghi lại 1 lần, backup raw trước)
    foreach ($scope in $pathChanges.Keys) {
        try {
            $subKey = if ($scope -eq 'Machine') { 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' } else { 'Environment' }
            $hive = if ($scope -eq 'Machine') { 'HKLM' } else { 'HKCU' }
            if ($scope -eq 'Machine' -and -not $isAdmin) { throw 'Cần Administrator cho PATH Machine' }
            $raw = Get-RawRegValue -Hive $hive -SubKey $subKey -ValueName 'Path'
            Set-Content -LiteralPath (Join-Path $backupDir "PATH_$scope.txt") -Value $raw -Encoding UTF8
            $entries = $raw -split ';'
            $keep = [System.Collections.Generic.List[string]]::new()
            for ($p = 0; $p -lt $entries.Count; $p++) {
                if ($pathChanges[$scope] -contains ($p + 1)) { continue }
                if ($entries[$p].Trim()) { $keep.Add($entries[$p].Trim().Trim('"')) }
            }
            $root = if ($hive -eq 'HKLM') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
            $key = $root.OpenSubKey($subKey, $true)
            try { $key.SetValue('Path', ($keep -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString) } finally { $key.Close() }
            Write-Host ("  √ [Path] {0}: xóa {1} mục" -f $scope, $pathChanges[$scope].Count) -ForegroundColor Green
            $log.Add("OK   [Path] $scope - removed $($pathChanges[$scope].Count) entries")
            $ok += $pathChanges[$scope].Count
        } catch {
            Write-Host ("  × [Path] {0} - {1}" -f $scope, $_.Exception.Message) -ForegroundColor Red
            $log.Add("FAIL [Path] $scope - $($_.Exception.Message)")
            $fail += $pathChanges[$scope].Count
        }
    }

    Set-Content -LiteralPath (Join-Path $backupDir 'cleanup.log') -Value $log -Encoding UTF8
    Write-Host ''
    Write-Host ($L.CleanDone -f $ok, $fail, $backupDir) -ForegroundColor $(if ($fail) { 'Yellow' } else { 'Green' })
    if ($fail -gt 0) { Write-Host $L.NeedAdmin -ForegroundColor DarkGray }
}

# ════════════════════════ FLOWS ════════════════════════

$scanModules = @(
    @{ Name = 'Path';      Fn = { Invoke-ScanPath } },
    @{ Name = 'EnvVars';   Fn = { Invoke-ScanEnvVars } },
    @{ Name = 'Folders';   Fn = { Invoke-ScanFolders } },
    @{ Name = 'Services';  Fn = { Invoke-ScanServices } },
    @{ Name = 'Startup';   Fn = { Invoke-ScanStartup } },
    @{ Name = 'Tasks';     Fn = { Invoke-ScanTasks } },
    @{ Name = 'Uninstall'; Fn = { Invoke-ScanUninstall } },
    @{ Name = 'AppPaths';  Fn = { Invoke-ScanAppPaths } },
    @{ Name = 'Shortcuts'; Fn = { Invoke-ScanShortcuts } },
    @{ Name = 'Firewall';  Fn = { Invoke-ScanFirewall } },
    @{ Name = 'Defender';  Fn = { Invoke-ScanDefender } },
    @{ Name = 'Certs';     Fn = { Invoke-ScanCerts } },
    @{ Name = 'IFEO';      Fn = { Invoke-ScanIFEO } },
    @{ Name = 'NativeMsg'; Fn = { Invoke-ScanNativeMsg } },
    @{ Name = 'Protocols'; Fn = { Invoke-ScanProtocols } },
    @{ Name = 'VendorReg'; Fn = { Invoke-ScanVendorReg } },
    @{ Name = 'Docker';    Fn = { Invoke-ScanDocker } },
    @{ Name = 'WSL';       Fn = { Invoke-ScanWSL } }
)

function Invoke-AllScans {
    param([hashtable]$L)
    $script:findings.Clear()
    $script:appFingerprint = $null
    Write-Host ''
    $mi = 0
    $totalSw = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($mod in $scanModules) {
        $mi++
        $before = $script:findings.Count
        # Spinner nền quay đều trong suốt thời gian module chạy (không đứng hình)
        # try/finally: module có ném lỗi thì spinner vẫn PHẢI được dập (tránh leak
        # luồng ghi console -> chữ đè lộn xộn lên menu về sau)
        $spinnerHandle = Start-ScanSpinner -Text ("[{0,2}/{1}] {2}..." -f $mi, $scanModules.Count, $mod.Name)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try { & $mod.Fn } finally { $sw.Stop(); Stop-ScanSpinner -Handle $spinnerHandle }
        $found = $script:findings.Count - $before
        $countColor = if ($found -gt 0) { [ConsoleColor]::Yellow } else { [ConsoleColor]::DarkGray }
        $redirected = $false
        try { $redirected = [Console]::IsOutputRedirected } catch {}
        if ($redirected) {
            Write-Host ("√ [{0,2}/{1}] {2,-12} {3,3} phát hiện  ({4:N1}s)" -f $mi, $scanModules.Count, $mod.Name, $found, $sw.Elapsed.TotalSeconds)
        } else {
            # Dòng chốt nhiều màu: tích XANH LÁ = đã quét xong, số phát hiện vàng nếu > 0
            $w = 120
            try { $w = [Console]::WindowWidth - 1 } catch {}
            Write-Host ("`r" + (' ' * $w) + "`r") -NoNewline
            Write-C '√ ' -Color Green -NoNewline
            Write-C ("[{0,2}/{1}] {2,-12} " -f $mi, $scanModules.Count, $mod.Name) -Color Gray -NoNewline
            Write-C ("{0,3} phát hiện" -f $found) -Color $countColor -NoNewline
            Write-C ("  ({0:N1}s)" -f $sw.Elapsed.TotalSeconds) -Color DarkGray
        }
    }
    $totalSw.Stop()
}

function Show-ScanSummary {
    param([hashtable]$L)
    Write-Host ''
    Write-Host ('═' * 60) -ForegroundColor Cyan
    Write-Host ("  {0}: {1}" -f $L.Scanning, $script:findings.Count) -ForegroundColor Cyan
    Write-Host ('═' * 60) -ForegroundColor Cyan
    foreach ($g in ($script:findings | Group-Object Category | Sort-Object Count -Descending)) {
        $high = @($g.Group | Where-Object Severity -eq 'High').Count
        $med  = @($g.Group | Where-Object Severity -eq 'Medium').Count
        $info = @($g.Group | Where-Object Severity -eq 'Info').Count
        $size = ($g.Group | Measure-Object SizeMB -Sum).Sum
        $sizeText = if ($size -gt 0) { " | {0:N0} MB" -f $size } else { '' }
        Write-Host ("  {0,-12} {1,3}  (High: {2}, Medium: {3}, Info: {4}){5}" -f $g.Name, $g.Count, $high, $med, $info, $sizeText)
    }
}

function Export-HtmlReport {
    param([string]$Path)
    $enc = { param($s) [System.Net.WebUtility]::HtmlEncode([string]$s) }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<!DOCTYPE html><html lang="vi"><head><meta charset="utf-8"><title>WinTrash Report</title><style>')
    [void]$sb.AppendLine('body{font-family:Segoe UI,Arial,sans-serif;margin:24px;background:#f6f8fa;color:#1f2328}h1{font-size:22px}.sub{color:#57606a;margin-bottom:16px}')
    [void]$sb.AppendLine('table{border-collapse:collapse;width:100%;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.08);margin-bottom:24px}')
    [void]$sb.AppendLine('th,td{border:1px solid #d0d7de;padding:6px 10px;text-align:left;font-size:13px;vertical-align:top}th{background:#eaeef2}td.mono{font-family:Consolas,monospace;word-break:break-all}')
    [void]$sb.AppendLine('.sev-High{background:#ffebe9}.sev-Medium{background:#fff8c5}.sev-Info{background:#f6f8fa}')
    [void]$sb.AppendLine('.badge{display:inline-block;padding:1px 8px;border-radius:10px;font-size:12px;font-weight:600}.b-High{background:#cf222e;color:#fff}.b-Medium{background:#bf8700;color:#fff}.b-Info{background:#6e7781;color:#fff}')
    [void]$sb.AppendLine('</style></head><body><h1>🧹 WinTrash Report</h1>')
    [void]$sb.AppendLine(('<div class="sub">{0} | {1} | Findings: {2}</div>' -f (& $enc $env:COMPUTERNAME), (Get-Date -Format 'yyyy-MM-dd HH:mm'), $script:findings.Count))
    [void]$sb.AppendLine('<table><tr><th>Category</th><th>Count</th><th>High</th><th>Medium</th><th>Info</th><th>MB</th></tr>')
    foreach ($g in ($script:findings | Group-Object Category | Sort-Object Count -Descending)) {
        [void]$sb.AppendLine(('<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5:N0}</td></tr>' -f (& $enc $g.Name), $g.Count,
            @($g.Group | Where-Object Severity -eq 'High').Count, @($g.Group | Where-Object Severity -eq 'Medium').Count,
            @($g.Group | Where-Object Severity -eq 'Info').Count, (($g.Group | Measure-Object SizeMB -Sum).Sum)))
    }
    [void]$sb.AppendLine('</table><table><tr><th>Sev</th><th>Category</th><th>Name</th><th>Target</th><th>Detail</th></tr>')
    $sevOrder = @{ High = 0; Medium = 1; Info = 2 }
    foreach ($f in ($script:findings | Sort-Object @{E={$sevOrder[$_.Severity]}}, Category, Name)) {
        [void]$sb.AppendLine(('<tr class="sev-{0}"><td><span class="badge b-{0}">{0}</span></td><td>{1}</td><td>{2}</td><td class="mono">{3}</td><td>{4}</td></tr>' -f `
            $f.Severity, (& $enc $f.Category), (& $enc $f.Name), (& $enc $f.Target), (& $enc $f.Detail)))
    }
    [void]$sb.AppendLine('</table><div class="sub">WinTrash Toolkit - MIT License</div></body></html>')
    [System.IO.File]::WriteAllText($Path, $sb.ToString(), [System.Text.UTF8Encoding]::new($true))
}

function Invoke-FlowScan {
    param([hashtable]$L)
    Request-MultiUserScan -L $L
    Invoke-AllScans -L $L
    Show-ScanSummary -L $L
    Save-ScanHistoryAndDiff -L $L
    $html = Join-Path $PSScriptRoot ("wintrash-report_{0}.html" -f (Get-Date -Format 'yyyyMMdd_HHmm'))
    Export-HtmlReport -Path $html
    Write-Host ''
    Write-Host ($L.ReportSaved -f $html) -ForegroundColor Green
    if ($script:Language -ne 'vi') { Write-Host $L.NoteVi -ForegroundColor DarkGray }
}

function Invoke-FlowClean {
    param([hashtable]$L, [switch]$DevOnly)
    if ($DevOnly) {
        $script:findings.Clear()
        $spinnerHandle = Start-ScanSpinner -Text 'DevTrash...'
        try { Invoke-ScanDevTrash } finally { Stop-ScanSpinner -Handle $spinnerHandle }
    } else {
        Request-MultiUserScan -L $L
        Invoke-AllScans -L $L
        Show-ScanSummary -L $L
    }
    # Áp danh sách bỏ qua (wintrash.ignore.json)
    $ignoreIds = @(Get-IgnoreList)
    $allRemovable = @($script:findings | Where-Object { $_.RemoveKind -ne 'None' })
    $removable = @($allRemovable | Where-Object { $ignoreIds -notcontains (Get-FindingId $_) })
    $hiddenCount = $allRemovable.Count - $removable.Count
    if ($hiddenCount -gt 0) {
        Write-Host ''
        Write-C ($L.IgnoredHidden -f $hiddenCount) -Color DarkGray
        Write-Host ''
    }
    if ($removable.Count -eq 0) {
        Write-Host ''
        Write-Host $L.NothingFound -ForegroundColor Green
        return
    }
    $labels = foreach ($f in $removable) {
        $sizeText = if ($f.SizeMB -gt 0) { " ({0:N0} MB)" -f $f.SizeMB } else { '' }
        "[{0}] {1}{2} → {3}" -f $f.Category, $f.Name, $sizeText, $f.Target
    }
    $sevs = foreach ($f in $removable) { $f.Severity }
    $selectedIdx = Show-CheckboxMenu -Labels @($labels) -Severities @($sevs) -Title $L.PickerTitle -Help $L.PickerHelp -AllowIgnore
    # Ghi các mục user bấm I vào ignore list (kể cả khi Esc)
    if ($script:pickerIgnored.Count -gt 0) {
        $newIgnoreIds = @($script:pickerIgnored | ForEach-Object { Get-FindingId $removable[$_] })
        Add-ToIgnoreList -Ids $newIgnoreIds
        Write-C ($L.IgnoredHidden -f $newIgnoreIds.Count) -Color DarkGray
        Write-Host ''
    }
    if ($null -eq $selectedIdx) { Write-Host $L.NoInteract -ForegroundColor Yellow; return }
    if ($selectedIdx.Count -eq 0) { Write-Host $L.NothingSel -ForegroundColor Yellow; return }

    $selected = @($selectedIdx | ForEach-Object { $removable[$_] })
    $answer = Read-Host ($L.ConfirmDel -f $selected.Count)
    if ($answer -notmatch '^[yY]') { Write-Host $L.NothingSel -ForegroundColor Yellow; return }

    # Chưa phải admin mà có mục cần admin -> đề nghị mở cửa sổ Administrator
    # (tránh cảnh cả trăm dòng lỗi "Access is denied" như trước)
    if (-not (Test-IsAdmin)) {
        $adminNeeded = @($selected | Where-Object { Test-FindingNeedsAdmin -Finding $_ })
        if ($adminNeeded.Count -gt 0 -and (Test-Interactive)) {
            $elevAnswer = Read-Host ($L.ElevateAsk -f $adminNeeded.Count, $selected.Count)
            if ($elevAnswer -match '^[yY]') {
                # Lưu danh sách ID đã chọn -> cửa sổ admin quét lại và dọn đúng các mục này
                $pendingDir = Join-Path $PSScriptRoot 'WinTrashBackups'
                if (-not (Test-Path -LiteralPath $pendingDir)) { New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null }
                $ids = @($selected | ForEach-Object { Get-FindingId $_ })
                ConvertTo-Json $ids | Set-Content -LiteralPath (Join-Path $pendingDir 'pending-clean.json') -Encoding UTF8
                $argStr = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Language {1} -Action clean-resume' -f $PSCommandPath, $script:Language
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argStr
                Write-Host $L.ElevateLaunched -ForegroundColor Green
                return
            }
            # Chọn n: chỉ dọn phần làm được ở quyền thường
            $selected = @($selected | Where-Object { -not (Test-FindingNeedsAdmin -Finding $_) })
            Write-Host ($L.SkippedAdmin -f $adminNeeded.Count) -ForegroundColor Yellow
            if ($selected.Count -eq 0) { return }
        }
    }
    Remove-SelectedFindings -Selected $selected -L $L
}

function Invoke-FlowCleanResume {
    # Chạy trong cửa sổ Administrator: đọc danh sách ID đã chọn, quét lại, dọn đúng các mục đó
    param([hashtable]$L)
    $pendingFile = Join-Path $PSScriptRoot 'WinTrashBackups\pending-clean.json'
    if (-not (Test-Path -LiteralPath $pendingFile)) { Write-Host $L.ResumeNothing -ForegroundColor Yellow; return }
    $ids = @(Get-Content -LiteralPath $pendingFile -Raw | ConvertFrom-Json)
    Remove-Item -LiteralPath $pendingFile -Force -ErrorAction SilentlyContinue
    Request-MultiUserScan -L $L -Auto   # bao phủ cả mục của user khác trong danh sách đã chọn
    Invoke-AllScans -L $L
    if (@($ids | Where-Object { $_ -like 'DevTrash|*' }).Count -gt 0) {
        $spinnerHandle = Start-ScanSpinner -Text 'DevTrash...'
        try { Invoke-ScanDevTrash } finally { Stop-ScanSpinner -Handle $spinnerHandle }
    }
    $selected = @($script:findings | Where-Object { $_.RemoveKind -ne 'None' -and $ids -contains (Get-FindingId $_) })
    if ($selected.Count -eq 0) { Write-Host $L.ResumeNothing -ForegroundColor Yellow; return }
    Remove-SelectedFindings -Selected $selected -L $L
}

function Invoke-FlowRestore {
    param([hashtable]$L)
    $backupRoot = Join-Path $PSScriptRoot 'WinTrashBackups'
    $backups = @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
    if ($backups.Count -eq 0) { Write-Host $L.RestoreNothing -ForegroundColor Yellow; return }

    Write-Host ''
    Write-Host $L.RestoreTitle -ForegroundColor Cyan
    for ($bi = 0; $bi -lt [Math]::Min($backups.Count, 15); $bi++) {
        $regCount = @(Get-ChildItem -LiteralPath $backups[$bi].FullName -Filter '*.reg' -ErrorAction SilentlyContinue).Count
        $xmlCount = @(Get-ChildItem -LiteralPath $backups[$bi].FullName -Filter '*.xml' -ErrorAction SilentlyContinue).Count
        Write-Host ("  {0}. {1}  ({2} .reg, {3} task)" -f ($bi + 1), $backups[$bi].Name, $regCount, $xmlCount)
    }
    if (-not (Test-Interactive)) { Write-Host $L.NoInteract -ForegroundColor Yellow; return }
    $choice = Read-Host '>'
    $sel = 0
    if (-not [int]::TryParse($choice, [ref]$sel) -or $sel -lt 1 -or $sel -gt $backups.Count) { return }
    $dir = $backups[$sel - 1].FullName

    $ok = 0; $fail = 0
    # 1. Import lại toàn bộ .reg
    foreach ($regFile in (Get-ChildItem -LiteralPath $dir -Filter '*.reg' -ErrorAction SilentlyContinue)) {
        & reg.exe import $regFile.FullName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-StatusLine ("  √ reg import: {0}" -f $regFile.Name) -Color Green -Persist; $ok++
        } else {
            Write-StatusLine ("  × reg import: {0} (cần admin?)" -f $regFile.Name) -Color Red -Persist; $fail++
        }
    }
    # 2. Đăng ký lại scheduled task từ manifest
    $manifest = Join-Path $dir 'tasks_manifest.txt'
    if (Test-Path -LiteralPath $manifest) {
        foreach ($line in (Get-Content -LiteralPath $manifest)) {
            $parts = $line -split '\|'
            if ($parts.Count -lt 3) { continue }
            $xmlPath = Join-Path $dir $parts[0]
            if (-not (Test-Path -LiteralPath $xmlPath)) { continue }
            try {
                Register-ScheduledTask -Xml (Get-Content -LiteralPath $xmlPath -Raw) -TaskPath $parts[1] -TaskName $parts[2] -Force -ErrorAction Stop | Out-Null
                Write-StatusLine ("  √ task: {0}{1}" -f $parts[1], $parts[2]) -Color Green -Persist; $ok++
            } catch {
                Write-StatusLine ("  × task: {0} - {1}" -f $parts[2], $_.Exception.Message) -Color Red -Persist; $fail++
            }
        }
    }
    # 3. Khôi phục PATH nếu có backup
    foreach ($scope in 'Machine', 'User') {
        $pathFile = Join-Path $dir "PATH_$scope.txt"
        if (-not (Test-Path -LiteralPath $pathFile)) { continue }
        try {
            $raw = (Get-Content -LiteralPath $pathFile -Raw).TrimEnd("`r", "`n")
            $subKey = if ($scope -eq 'Machine') { 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' } else { 'Environment' }
            $root = if ($scope -eq 'Machine') { [Microsoft.Win32.Registry]::LocalMachine } else { [Microsoft.Win32.Registry]::CurrentUser }
            $key = $root.OpenSubKey($subKey, $true)
            try { $key.SetValue('Path', $raw, [Microsoft.Win32.RegistryValueKind]::ExpandString) } finally { $key.Close() }
            Write-StatusLine ("  √ PATH {0}" -f $scope) -Color Green -Persist; $ok++
        } catch {
            Write-StatusLine ("  × PATH {0} - {1}" -f $scope, $_.Exception.Message) -Color Red -Persist; $fail++
        }
    }
    Write-Host ''
    Write-Host ($L.RestoreDone -f $ok, $fail) -ForegroundColor $(if ($fail) { 'Yellow' } else { 'Green' })
    Write-Host 'Lưu ý: thư mục/file đã vào Recycle Bin thì Restore từ Recycle Bin của Windows.' -ForegroundColor DarkGray
}

function Invoke-FlowTemp {
    param([hashtable]$L)
    $targets = @(
        @{ Label = 'User Temp';    Path = $env:TEMP },
        @{ Label = 'Windows Temp'; Path = (Join-Path $env:SystemRoot 'Temp') },
        @{ Label = 'CrashDumps';   Path = (Join-Path $env:LOCALAPPDATA 'CrashDumps') }
    )
    $cutoff = (Get-Date).AddHours(-24)
    Write-Host ''
    Write-Host $L.TempTitle -ForegroundColor Cyan
    $allFiles = [System.Collections.Generic.List[object]]::new()
    foreach ($t in $targets) {
        if (-not (Test-Path -LiteralPath $t.Path)) { continue }
        Write-StatusLine ("  {0} {1}..." -f (Get-SpinFrame), $t.Label)
        $files = @(Get-ChildItem -LiteralPath $t.Path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff })
        $sizeMB = [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 0)
        foreach ($f in $files) { $allFiles.Add($f) }
        Write-StatusLine ("  √ {0,-14} {1,6} file, {2,8:N0} MB   ({3})" -f $t.Label, $files.Count, $sizeMB, $t.Path) -Color Gray -Persist
    }
    $totalMB = [math]::Round((($allFiles | Measure-Object Length -Sum).Sum) / 1MB, 0)
    if ($allFiles.Count -eq 0 -or $totalMB -lt 1) { Write-Host $L.TempNothing -ForegroundColor Green; return }
    if (-not (Test-Interactive)) { Write-Host $L.NoInteract -ForegroundColor Yellow; return }

    $answer = Read-Host ($L.TempConfirm -f $totalMB)
    if ($answer -notmatch '^[yY]') { Write-Host $L.NothingSel -ForegroundColor Yellow; return }
    $deleted = 0; $freedBytes = 0
    foreach ($f in $allFiles) {
        try {
            $len = $f.Length
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            $deleted++; $freedBytes += $len
        } catch {}   # file đang bị khóa - bỏ qua, không sao
    }
    # Dọn thư mục rỗng còn sót trong Temp user
    Get-ChildItem -LiteralPath $env:TEMP -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue)) {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host ($L.TempDone -f [math]::Round($freedBytes / 1MB, 0), $deleted) -ForegroundColor Green
}

function Invoke-FlowSchedule {
    param([hashtable]$L)
    $taskName = 'WinTrash Monthly Scan'
    $exists = $null -ne (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)
    if ($exists) {
        if (Test-Interactive) {
            $answer = Read-Host $L.SchedAskRemove
            if ($answer -match '^[yY]') {
                & schtasks.exe /Delete /TN $taskName /F 2>$null | Out-Null
                Write-Host $L.SchedRemoved -ForegroundColor Green
            }
        } else {
            Write-Host $L.SchedAskRemove -ForegroundColor Yellow
        }
        return
    }
    # $PSCommandPath (không hardcode tên file): user đổi tên script (vd "WinTrash (1).ps1")
    # thì task vẫn trỏ đúng file đang chạy; schtasks không validate /TR nên trỏ sai
    # là fail im lặng vĩnh viễn dù báo tạo thành công
    $scriptPath = $PSCommandPath
    $tr = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"{0}\" -Language {1} -Role User -Action scan' -f $scriptPath, $script:Language
    # PS 7.3+ mặc định PSNativeCommandArgumentPassing='Windows' sẽ escape LẠI chuỗi \"
    # thành \\\" -> task lưu literal \" quanh đường dẫn và không bao giờ chạy được.
    # Ép 'Legacy' trong scope con để giữ đúng hành vi PS 5.1 (trên 5.1 gán biến này vô hại).
    & {
        $PSNativeCommandArgumentPassing = 'Legacy'
        schtasks.exe /Create /SC MONTHLY /D 1 /ST 09:03 /TN $taskName /TR $tr /F 2>$null
    } | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host ($L.SchedCreated -f $taskName) -ForegroundColor Green
    } else {
        Write-Host ("× schtasks exit code {0}" -f $LASTEXITCODE) -ForegroundColor Red
    }
}

function Invoke-FlowDownloads {
    param([hashtable]$L)
    $dl = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -ErrorAction SilentlyContinue).'{374DE290-123F-4565-9164-39C4925E467B}'
    if (-not $dl) { $dl = Join-Path $env:USERPROFILE 'Downloads' }
    $dl = [Environment]::ExpandEnvironmentVariables($dl)

    $categories = [ordered]@{
        'Documents'  = @('.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.md', '.csv', '.odt', '.ods', '.rtf', '.epub', '.mobi', '.xps', '.one')
        'Images'     = @('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp', '.ico', '.heic', '.tif', '.tiff', '.raw', '.psd', '.ai', '.avif')
        'Videos'     = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.webm', '.flv', '.m4v', '.ts', '.mpg', '.mpeg')
        'Audio'      = @('.mp3', '.wav', '.flac', '.m4a', '.ogg', '.aac', '.wma', '.opus', '.mid')
        'Archives'   = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.tgz', '.cab')
        'Installers' = @('.exe', '.msi', '.msix', '.msixbundle', '.appx', '.appxbundle', '.msu', '.apk', '.ipa')
        'DiskImages' = @('.iso', '.img', '.vhd', '.vhdx', '.dmg', '.wim')
        'Code'       = @('.js', '.ts', '.py', '.ps1', '.sh', '.bat', '.cmd', '.json', '.xml', '.yml', '.yaml', '.sql', '.ipynb', '.c', '.cpp', '.cs', '.java', '.go', '.rs', '.html', '.css')
        'Fonts'      = @('.ttf', '.otf', '.woff', '.woff2')
        'Torrents'   = @('.torrent')
        'Subtitles'  = @('.srt', '.ass', '.vtt')
    }
    $skipExt = @('.crdownload', '.part', '.partial', '.tmp', '.download', '.opdownload', '.!ut')
    $ageCutoff = (Get-Date).AddHours(-1)

    $plan = [System.Collections.Generic.List[object]]::new()
    foreach ($file in (Get-ChildItem -LiteralPath $dl -File -ErrorAction SilentlyContinue)) {
        $ext = $file.Extension.ToLowerInvariant()
        if ($file.Name -eq 'desktop.ini' -or $skipExt -contains $ext) { continue }
        if ($file.LastWriteTime -gt $ageCutoff) { continue }
        foreach ($cat in $categories.Keys) {
            if ($categories[$cat] -contains $ext) {
                $plan.Add([PSCustomObject]@{ File = $file; Category = $cat })
                break
            }
        }
    }
    if ($plan.Count -eq 0) { Write-Host $L.DlNothing -ForegroundColor Green; return }

    $groups = @($plan | Group-Object Category | Sort-Object Count -Descending)
    $labels = foreach ($g in $groups) {
        $size = [math]::Round((($g.Group.File | Measure-Object Length -Sum).Sum) / 1MB, 0)
        "{0}  -  {1} file, {2:N0} MB" -f $g.Name, $g.Count, $size
    }
    $selectedIdx = Show-CheckboxMenu -Labels @($labels) -Title $L.DlTitle -Help $L.PickerHelp
    if ($null -eq $selectedIdx) { Write-Host $L.NoInteract -ForegroundColor Yellow; return }
    if ($selectedIdx.Count -eq 0) { Write-Host $L.NothingSel -ForegroundColor Yellow; return }

    $undoLog = [System.Collections.Generic.List[object]]::new()
    $moved = 0
    foreach ($gi in $selectedIdx) {
        $group = $groups[$gi]
        $targetDir = Join-Path $dl $group.Name
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        foreach ($item in $group.Group) {
            try {
                $destPath = Join-Path $targetDir $item.File.Name
                $counter = 1
                while (Test-Path -LiteralPath $destPath) {
                    $destPath = Join-Path $targetDir ("{0} ({1}){2}" -f $item.File.BaseName, $counter, $item.File.Extension)
                    $counter++
                }
                Move-Item -LiteralPath $item.File.FullName -Destination $destPath
                $undoLog.Add([PSCustomObject]@{ From = $item.File.FullName; To = $destPath })
                $moved++
            } catch {
                Write-Host ("  × {0}: {1}" -f $item.File.Name, $_.Exception.Message) -ForegroundColor Red
            }
        }
        Write-Host ("  √ {0}: {1} file" -f $group.Name, $group.Count) -ForegroundColor Green
    }
    if ($undoLog.Count -gt 0) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $logDir = Join-Path $PSScriptRoot 'DownloadsLogs'
        if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        $undoPath = Join-Path $logDir "Undo-Downloads_$timestamp.ps1"
        $undoLines = [System.Collections.Generic.List[string]]::new()
        $undoLines.Add('$ErrorActionPreference = "Continue"')
        foreach ($entry in $undoLog) {
            $from = $entry.To -replace "'", "''"
            $to = $entry.From -replace "'", "''"
            $undoLines.Add("Move-Item -LiteralPath '$from' -Destination '$to' -ErrorAction Continue")
        }
        Set-Content -LiteralPath $undoPath -Value $undoLines -Encoding UTF8
        $undoLog | Export-Csv -LiteralPath (Join-Path $logDir "moves_$timestamp.csv") -NoTypeInformation -Encoding UTF8
        Write-Host ''
        Write-Host ($L.DlDone -f $moved, $undoPath) -ForegroundColor Green
    }
}

function Invoke-FlowInstall {
    param([hashtable]$L, [string]$Package)
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) { Write-Host $L.NeedNode -ForegroundColor Red; return }
    try {
        $ver = (& node --version) -replace '^v', ''
        if ([version]$ver -lt [version]'18.0') { Write-Host $L.NeedNode -ForegroundColor Red; return }
    } catch {}
    # Chạy TRỰC TIẾP trong console (không spinner, không cửa sổ ẩn):
    # - người dùng thấy tiến trình thật của npm/npx
    # - installer TƯƠNG TÁC như Claudefy (có menu chọn) hoạt động bình thường
    #   (trước đây chạy ẩn -> installer chờ phím trong cửa sổ vô hình = tưởng bị treo)
    Write-Host ''
    Write-C ("═══ {0} {1} ═══" -f $L.Installing, $Package) -Color Cyan
    Write-Host ''
    if ($Package -eq 'devradar') {
        & npm install -g '@hasoftware/devradar'
    } else {
        & npx --yes '@hasoftware/claudefy'
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Host ''
        Write-C ("√ {0}" -f $L.InstallOk) -Color Green
        Write-Host ''
    } else {
        Write-Host ''
        Write-C ("× " + ($L.InstallFail -f "exit code $LASTEXITCODE")) -Color Red
        Write-Host ''
    }
}

# ════════════════════════ SELF-UPDATE ════════════════════════

function Get-RemoteVersion {
    # Đọc file VERSION trên GitHub - lỗi mạng thì trả null (bỏ qua êm)
    try {
        $resp = Invoke-WebRequest -Uri ($script:UpdateRawBase + '/VERSION') -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        return [version](([string]$resp.Content).Trim())
    } catch { return $null }
}

function Get-RemoteChangelog {
    # Đọc CHANGELOG.md trên GitHub - lỗi mạng thì trả null (bỏ qua êm, vẫn hỏi update)
    try {
        $resp = Invoke-WebRequest -Uri ($script:UpdateRawBase + '/CHANGELOG.md') -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        return [string]$resp.Content
    } catch { return $null }
}

function Get-ChangelogForUpdate {
    # Trích từ CHANGELOG.md các mục có phiên bản NẰM TRONG (Current, Remote] - người dùng
    # thấy đúng những gì mình sắp nhận, kể cả khi nhảy cóc nhiều bản. Hàm thuần túy để
    # test không cần mạng; markdown rỗng/hỏng -> danh sách rỗng.
    param([string]$Markdown, [version]$Current, [version]$Remote)
    $out = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Markdown)) { return $out }
    $include = $false
    foreach ($line in ($Markdown -split "`r?`n")) {
        $m = [regex]::Match($line, '^##\s*\[(\d+(?:\.\d+){1,3})\]\s*(.*)$')
        if ($m.Success) {
            $v = $null
            $include = [version]::TryParse($m.Groups[1].Value, [ref]$v) -and ($v -gt $Current) -and ($v -le $Remote)
            if ($include) { $out.Add(('[{0}] {1}' -f $m.Groups[1].Value, $m.Groups[2].Value).TrimEnd()) }
            continue
        }
        if (-not $include) { continue }
        $clean = ($line -replace '\*\*', '').TrimEnd()
        if ($clean -match '^###\s*(.+)$') { $out.Add($Matches[1] + ':'); continue }
        if ($clean.Trim()) { $out.Add($clean) }
    }
    return $out
}

function Invoke-SelfUpdate {
    param([hashtable]$L)
    try {
        $tmp = Join-Path $env:TEMP 'WinTrash.new.ps1'
        Invoke-WebRequest -Uri ($script:UpdateRawBase + '/WinTrash.ps1') -OutFile $tmp -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        # Kiểm tra file tải về: phải parse được và đúng là WinTrash
        $errs = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$errs)
        if ($errs.Count -gt 0) { throw 'file tải về bị lỗi cú pháp' }
        if ((Get-Content -LiteralPath $tmp -Raw) -notmatch 'WinTrashVersion') { throw 'file tải về không hợp lệ' }
        # Backup bản hiện tại rồi thay thế
        Copy-Item -LiteralPath $PSCommandPath -Destination ($PSCommandPath + '.bak') -Force
        Copy-Item -LiteralPath $tmp -Destination $PSCommandPath -Force
        return $true
    } catch {
        Write-Host ($L.UpdateFail -f $_.Exception.Message) -ForegroundColor Yellow
        return $false
    }
}

function Test-UpdatePrompt {
    # Gọi sau khi chọn ngôn ngữ: có bản mới -> hiện "có gì mới" rồi hỏi update/skip.
    # Trả $true nếu đã update (cần restart).
    param([hashtable]$L)
    Write-C $L.UpdateCheck -Color DarkGray
    Write-Host ''
    $remote = Get-RemoteVersion
    if (-not $remote -or $remote -le $script:WinTrashVersion) { return $false }
    # Có gì mới giữa bản đang dùng và bản mới - tải/parse lỗi thì bỏ qua êm, vẫn hỏi update
    $notes = @(Get-ChangelogForUpdate -Markdown (Get-RemoteChangelog) -Current $script:WinTrashVersion -Remote $remote)
    if ($notes.Count -gt 0) {
        Write-C ($L.UpdateWhatsNew -f $remote) -Color Cyan
        foreach ($line in ($notes | Select-Object -First 30)) {
            $color = if ($line -match '^\[') { 'Yellow' } elseif ($line -match '^- ') { 'Gray' } else { 'DarkCyan' }
            Write-Host ('  ' + $line) -ForegroundColor $color
        }
        if ($notes.Count -gt 30) { Write-Host ('  ' + ($L.UpdateMoreNotes -f ($notes.Count - 30))) -ForegroundColor DarkGray }
        Write-Host ''
    }
    $answer = Read-Host ($L.UpdateFound -f $remote, $script:WinTrashVersion)
    if ($answer -notmatch '^[yY]') { return $false }
    if (-not (Invoke-SelfUpdate -L $L)) { return $false }
    Write-Host $L.UpdateDone -ForegroundColor Green
    Start-Sleep -Milliseconds 800
    return $true
}

# ════════════════════════ MAIN ════════════════════════

# Chế độ test (Pester): dot-source script để lấy các hàm, không chạy main
if ($env:WINTRASH_TEST -eq '1') { return }

$tagline = 'WinTrash Toolkit — Windows leftovers scanner & cleaner | MIT License'

function Invoke-OneAction {
    param([hashtable]$L, [string]$Key)
    switch ($Key) {
        'scan'             { Invoke-FlowScan -L $L }
        'clean'            { Invoke-FlowClean -L $L }
        'downloads'        { Invoke-FlowDownloads -L $L }
        'temp'             { Invoke-FlowTemp -L $L }
        'restore'          { Invoke-FlowRestore -L $L }
        'schedule'         { Invoke-FlowSchedule -L $L }
        'devscan'          { Invoke-FlowClean -L $L -DevOnly }
        'install-devradar' { Invoke-FlowInstall -L $L -Package 'devradar' }
        'install-claudefy' { Invoke-FlowInstall -L $L -Package 'claudefy' }
        'clean-resume'     { Invoke-FlowCleanResume -L $L }
    }
}

# ---- Chế độ chạy thẳng (-Action): không wizard, không Clear-Host ----
if ($Action) {
    if (-not $Language) { $Language = 'vi' }
    if (-not $Role) { $Role = 'User' }
    $script:Language = $Language
    $L = $i18n[$Language]
    Show-Banner -Tagline $tagline
    Show-Spinner -Label $L.Init
    Invoke-OneAction -L $L -Key $Action
    # Cửa sổ admin mở riêng cho clean-resume: giữ lại để người dùng đọc kết quả
    if ($Action -eq 'clean-resume' -and (Test-Interactive)) { Read-Host $L.PressEnter | Out-Null }
    return
}

# ---- Không tương tác mà cũng không có -Action: hướng dẫn rồi thoát ----
if (-not (Test-Interactive)) {
    $script:Language = if ($Language) { $Language } else { 'vi' }
    Show-Banner -Tagline $tagline
    Write-Host 'Console không tương tác. Dùng: .\WinTrash.ps1 -Language vi -Role User -Action scan|clean|temp|restore|downloads|schedule'
    return
}

# ---- WIZARD: mỗi bước một màn hình sạch (banner giữ trên đỉnh), có Quay lại ----
function Show-WizardScreen {
    Stop-LeakedSpinner      # dập spinner nền còn sót (nếu có) trước khi vẽ màn mới
    Clear-PendingInput      # nuốt phím Enter bấm thừa để không nhảy màn hình
    Clear-Screen            # xóa viewport + scrollback + con trỏ về (0,0)
    Show-Banner -Tagline $tagline
}

$langChoice = $Language
$roleChoice = $Role

while ($true) {
    # Bước 1: chọn ngôn ngữ
    if (-not $langChoice) {
        Show-WizardScreen
        Write-Host $i18n.vi.ChooseLang -ForegroundColor Cyan
        Write-Host '  1. Tiếng Việt'
        Write-Host '  2. English'
        Write-Host '  3. 中文'
        Write-Host '  4. Русский'
        $choice = Read-Host '>'
        $langChoice = switch ($choice) { '1' { 'vi' } '2' { 'en' } '3' { 'zh' } '4' { 'ru' } default { $null } }
        if (-not $langChoice) { continue }   # gõ sai -> hỏi lại
    }
    $script:Language = $langChoice
    $L = $i18n[$langChoice]

    # Kiểm tra cập nhật MỘT lần, ngay sau khi chọn ngôn ngữ
    if (-not $script:updateChecked) {
        $script:updateChecked = $true
        if (Test-UpdatePrompt -L $L) {
            # Đã thay file bằng bản mới -> chạy lại chính mình với ngôn ngữ đã chọn
            & $PSCommandPath -Language $langChoice
            return
        }
    }

    # Bước 2: chọn vai trò (0 = quay lại chọn ngôn ngữ)
    if (-not $roleChoice) {
        Show-WizardScreen
        Write-Host $L.ChooseRole -ForegroundColor Cyan
        Write-Host ("  1. {0}" -f $L.RoleUser)
        Write-Host ("  2. {0}" -f $L.RoleDev)
        Write-Host ("  0. {0}" -f $L.Back) -ForegroundColor DarkGray
        $choice = Read-Host '>'
        if ($choice -eq '0') { $langChoice = $null; continue }
        $roleChoice = switch ($choice) { '1' { 'User' } '2' { 'Developer' } default { $null } }
        if (-not $roleChoice) { continue }
    }
    $Role = $roleChoice

    # Bước 3: menu chính (B = đổi ngôn ngữ/vai trò, 0 = thoát)
    $menuItems = [System.Collections.Generic.List[object]]::new()
    $menuItems.Add(@{ Key = 'scan';      Label = $L.MenuScan })
    $menuItems.Add(@{ Key = 'clean';     Label = $L.MenuClean })
    $menuItems.Add(@{ Key = 'downloads'; Label = $L.MenuDl })
    $menuItems.Add(@{ Key = 'temp';      Label = $L.MenuTemp })
    $menuItems.Add(@{ Key = 'restore';   Label = $L.MenuRestore })
    $menuItems.Add(@{ Key = 'schedule';  Label = $L.MenuSched })
    if ($Role -eq 'Developer') {
        $menuItems.Add(@{ Key = 'devscan';          Label = $L.MenuDevScan })
        $menuItems.Add(@{ Key = 'install-devradar'; Label = $L.MenuRadar })
        $menuItems.Add(@{ Key = 'install-claudefy'; Label = $L.MenuClaudefy })
    }

    $backToSetup = $false
    while ($true) {
        Show-WizardScreen
        Write-Host ('═' * 60) -ForegroundColor Cyan
        Write-Host ("  {0}   [{1} | {2}]" -f $L.MenuTitle, $script:Language.ToUpper(), $Role) -ForegroundColor Cyan
        Write-Host ('═' * 60) -ForegroundColor Cyan
        for ($mi = 0; $mi -lt $menuItems.Count; $mi++) {
            Write-Host ("  {0}. {1}" -f ($mi + 1), $menuItems[$mi].Label)
        }
        Write-Host ("  B. {0}" -f $L.MenuSwitch) -ForegroundColor DarkGray
        Write-Host ("  0. {0}" -f $L.MenuExit)

        $choice = Read-Host $L.Prompt
        if ($choice -eq '0') { return }
        if ($choice -match '^[bB]$') { $roleChoice = $null; $backToSetup = $true; break }
        $sel = 0
        if ([int]::TryParse($choice, [ref]$sel) -and $sel -ge 1 -and $sel -le $menuItems.Count) {
            Show-WizardScreen
            Invoke-OneAction -L $L -Key $menuItems[$sel - 1].Key
            Stop-LeakedSpinner
            Clear-PendingInput
            Read-Host $L.PressEnter | Out-Null
        } else {
            Write-Host $L.Invalid -ForegroundColor Red
            Start-Sleep -Milliseconds 700
        }
    }
    if ($backToSetup) { continue }
}
