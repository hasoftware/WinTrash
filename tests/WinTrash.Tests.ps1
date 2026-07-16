# Pester 5 tests cho các hàm thuần túy của WinTrash.ps1
# Chạy: Invoke-Pester -Path tests\
# Cơ chế: đặt WINTRASH_TEST=1 rồi dot-source script -> chỉ nạp hàm, không chạy main.

BeforeAll {
    $env:WINTRASH_TEST = '1'
    . (Join-Path $PSScriptRoot '..\WinTrash.ps1')
}

AfterAll {
    Remove-Item Env:\WINTRASH_TEST -ErrorAction SilentlyContinue
}

Describe 'Remove-Diacritics' {
    It 'bỏ dấu tiếng Việt: Cốc Cốc -> Coc Coc' {
        Remove-Diacritics -Text 'Cốc Cốc' | Should -Be 'Coc Coc'
    }
    It 'xử lý chữ đ/Đ' {
        Remove-Diacritics -Text 'Đường dẫn' | Should -Be 'Duong dan'
    }
    It 'giữ nguyên chuỗi ASCII' {
        Remove-Diacritics -Text 'Hello World 123' | Should -Be 'Hello World 123'
    }
}

Describe 'Get-NameTokens' {
    It 'tách token và lowercase' {
        Get-NameTokens -Text 'Adobe Photoshop 2025' | Should -Contain 'adobe'
        Get-NameTokens -Text 'Adobe Photoshop 2025' | Should -Contain 'photoshop'
    }
    It 'loại stop-words' {
        Get-NameTokens -Text 'The Software Company Inc' | Should -Not -Contain 'the'
        Get-NameTokens -Text 'The Software Company Inc' | Should -Not -Contain 'software'
    }
    It 'bỏ dấu trước khi tách: Cốc Cốc -> coc' {
        Get-NameTokens -Text 'Cốc Cốc' | Should -Contain 'coc'
    }
    It 'chuỗi rỗng trả về mảng rỗng' {
        @(Get-NameTokens -Text '') | Should -HaveCount 0
    }
}

Describe 'Resolve-CommandPath' {
    It 'đường dẫn có nháy kép + tham số' {
        Resolve-CommandPath -CommandLine '"C:\Program Files\App\app.exe" --flag' |
            Should -Be 'C:\Program Files\App\app.exe'
    }
    It 'đường dẫn thật không nháy (cmd.exe có thật)' {
        $result = Resolve-CommandPath -CommandLine "$env:SystemRoot\System32\cmd.exe /c echo hi"
        $result | Should -Be "$env:SystemRoot\System32\cmd.exe"
    }
    It 'không sập với nháy kép giữa lệnh (bug cmd /c "rmdir")' {
        { Resolve-CommandPath -CommandLine 'C:\App\run.exe \c "rmdir \S \Q C:\x"' } | Should -Not -Throw
    }
    It 'đường dẫn không nháy có dấu cách, exe đã mất -> bắt theo đuôi .exe' {
        Resolve-CommandPath -CommandLine 'C:\Program Files\Gone App\gone.exe %1' |
            Should -Be 'C:\Program Files\Gone App\gone.exe'
    }
    It 'chuỗi rỗng trả về null' {
        Resolve-CommandPath -CommandLine '' | Should -BeNullOrEmpty
    }
}

Describe 'Test-ExeMissing' {
    It 'file có thật -> false' {
        Test-ExeMissing -ExePath "$env:SystemRoot\System32\cmd.exe" | Should -BeFalse
    }
    It 'file không tồn tại -> true' {
        Test-ExeMissing -ExePath 'C:\definitely\not\here\ghost.exe' | Should -BeTrue
    }
    It 'đường dẫn chứa ký tự bất hợp lệ -> false (không báo nhầm)' {
        Test-ExeMissing -ExePath 'C:\App\x.exe \c "rm"' | Should -BeFalse
    }
    It 'chuỗi rỗng -> false' {
        Test-ExeMissing -ExePath '' | Should -BeFalse
    }
}

Describe 'ConvertTo-RegExePath' {
    It 'HKLM: -> HKEY_LOCAL_MACHINE' {
        ConvertTo-RegExePath -PSPath 'HKLM:\SOFTWARE\Test' | Should -Be 'HKEY_LOCAL_MACHINE\SOFTWARE\Test'
    }
    It 'HKCU: -> HKEY_CURRENT_USER' {
        ConvertTo-RegExePath -PSPath 'HKCU:\Environment' | Should -Be 'HKEY_CURRENT_USER\Environment'
    }
    It 'bóc prefix Registry::' {
        ConvertTo-RegExePath -PSPath 'Registry::HKEY_CLASSES_ROOT\zax' | Should -Be 'HKEY_CLASSES_ROOT\zax'
    }
    It 'bóc prefix Microsoft.PowerShell.Core' {
        ConvertTo-RegExePath -PSPath 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\X' |
            Should -Be 'HKEY_LOCAL_MACHINE\X'
    }
}

Describe 'Get-FindingId' {
    It 'sinh ID ổn định Category|Name|Target' {
        $f = [PSCustomObject]@{ Category = 'Path'; Name = 'User #3'; Target = 'C:\x' }
        Get-FindingId $f | Should -Be 'Path|User #3|C:\x'
    }
}

Describe 'Get-SeverityColor' {
    It 'High -> Red'    { Get-SeverityColor -Severity 'High'   | Should -Be ([ConsoleColor]::Red) }
    It 'Medium -> Yellow' { Get-SeverityColor -Severity 'Medium' | Should -Be ([ConsoleColor]::Yellow) }
    It 'Info -> Blue'   { Get-SeverityColor -Severity 'Info'   | Should -Be ([ConsoleColor]::Blue) }
}

Describe 'Get-ChangelogForUpdate' {
    BeforeAll {
        $sampleMd = @"
# Changelog

## [1.3.0] - 2026-07-09

### Thêm
- **Quét Docker**: phát hiện tàn dư Docker Desktop.

## [1.2.2] - 2026-07-07

### Sửa
- **Lỗi X**: đã sửa xong.

## [1.0.0] - 2026-07-06

Phiên bản đầu tiên.
"@
    }
    It 'chỉ lấy các bản trong khoảng (Current, Remote]' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.2.2') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Match '\[1\.3\.0\]'
        ($r -join "`n") | Should -Not -Match '\[1\.2\.2\]'
        ($r -join "`n") | Should -Not -Match '\[1\.0\.0\]'
    }
    It 'gộp đủ các bản khi người dùng nhảy cóc nhiều phiên bản' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.0.0') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Match '\[1\.3\.0\]'
        ($r -join "`n") | Should -Match '\[1\.2\.2\]'
        ($r -join "`n") | Should -Not -Match '\[1\.0\.0\]'
    }
    It 'bỏ markdown đậm ** nhưng giữ nội dung' {
        $r = @(Get-ChangelogForUpdate -Markdown $sampleMd -Current ([version]'1.2.2') -Remote ([version]'1.3.0'))
        ($r -join "`n") | Should -Not -Match '\*\*'
        ($r -join "`n") | Should -Match 'Quét Docker'
        ($r -join "`n") | Should -Match 'Thêm:'
    }
    It 'markdown rỗng/null -> danh sách rỗng, không ném lỗi' {
        @(Get-ChangelogForUpdate -Markdown '' -Current ([version]'1.0') -Remote ([version]'2.0')) | Should -HaveCount 0
        @(Get-ChangelogForUpdate -Markdown $null -Current ([version]'1.0') -Remote ([version]'2.0')) | Should -HaveCount 0
    }
    It 'header phiên bản không hợp lệ thì bỏ qua, không sập' {
        $bad = "## [abc] - hỏng`n- dòng rác`n## [2.0.0]`n- dòng thật"
        $r = @(Get-ChangelogForUpdate -Markdown $bad -Current ([version]'1.0') -Remote ([version]'2.0.0'))
        ($r -join "`n") | Should -Match 'dòng thật'
        ($r -join "`n") | Should -Not -Match 'dòng rác'
    }
    It 'section ## không phải phiên bản đặt SAU bản được chọn không lọt vào notes' {
        $md2 = "## [1.5.0]`n- muc moi`n## [Unreleased]`n- chua phat hanh`n## Ghi chu`n- linh tinh"
        $r = @(Get-ChangelogForUpdate -Markdown $md2 -Current ([version]'1.0') -Remote ([version]'2.0'))
        ($r -join "`n") | Should -Match 'muc moi'
        ($r -join "`n") | Should -Not -Match 'chua phat hanh'
        ($r -join "`n") | Should -Not -Match 'linh tinh'
    }
    It 'dòng link-reference kiểu keep-a-changelog bị loại' {
        $md3 = "## [1.5.0]`n- muc moi`n[1.5.0]: https://example.com/diff"
        $r = @(Get-ChangelogForUpdate -Markdown $md3 -Current ([version]'1.0') -Remote ([version]'2.0'))
        ($r -join "`n") | Should -Not -Match 'example.com'
    }
    It 'VERSION 2 thành phần vẫn khớp header 3 thành phần (1.4 vs [1.4.0])' {
        $md4 = "## [1.4.0]`n- noi dung ban moi"
        $r = @(Get-ChangelogForUpdate -Markdown $md4 -Current ([version]'1.3.0') -Remote ([version]'1.4'))
        ($r -join "`n") | Should -Match 'noi dung ban moi'
    }
}

Describe 'ConvertTo-PaddedVersion' {
    It 'đủ 4 thành phần, thiếu điền 0' {
        ConvertTo-PaddedVersion ([version]'1.4') | Should -Be ([version]'1.4.0.0')
        ConvertTo-PaddedVersion ([version]'1.4.0') | Should -Be ([version]'1.4.0.0')
        ConvertTo-PaddedVersion ([version]'2.0.1.7') | Should -Be ([version]'2.0.1.7')
    }
    It '1.4 và 1.4.0 so sánh bằng nhau sau chuẩn hóa' {
        (ConvertTo-PaddedVersion ([version]'1.4')) -eq (ConvertTo-PaddedVersion ([version]'1.4.0')) | Should -BeTrue
    }
}

Describe 'Danh sách module quét' {
    It 'có đúng 18 module, gồm Docker và WSL' {
        @($scanModules).Count | Should -Be 18
        @($scanModules | ForEach-Object { $_.Name }) | Should -Contain 'Docker'
        @($scanModules | ForEach-Object { $_.Name }) | Should -Contain 'WSL'
    }
}

Describe 'Select-RamAppCandidates' {
    It 'chỉ lấy tiến trình có cửa sổ, loại shell/console-host và chính mình' {
        $procs = @(
            [PSCustomObject]@{ Id = 100; ProcessName = 'notepad';         MainWindowHandle = [IntPtr]123 },
            [PSCustomObject]@{ Id = 101; ProcessName = 'chrome';          MainWindowHandle = [IntPtr]456 },
            [PSCustomObject]@{ Id = 102; ProcessName = 'svchost';         MainWindowHandle = [IntPtr]::Zero },
            [PSCustomObject]@{ Id = 103; ProcessName = 'explorer';        MainWindowHandle = [IntPtr]789 },
            [PSCustomObject]@{ Id = 104; ProcessName = 'WindowsTerminal'; MainWindowHandle = [IntPtr]11 },
            [PSCustomObject]@{ Id = 105; ProcessName = 'paint';           MainWindowHandle = [IntPtr]::Zero },
            [PSCustomObject]@{ Id = 999; ProcessName = 'code';            MainWindowHandle = [IntPtr]22 }
        )
        $r = @(Select-RamAppCandidates -Processes $procs -SelfId 999)
        @($r | ForEach-Object { $_.Id }) | Should -Be @(100, 101)
    }
    It 'danh sách rỗng không ném lỗi' {
        @(Select-RamAppCandidates -Processes @() -SelfId 1) | Should -HaveCount 0
    }
}

Describe 'Bảng i18n' {
    It '4 ngôn ngữ có cùng tập khóa chuỗi (không được thiếu chuỗi ở ngôn ngữ nào)' {
        $viKeys = (@($i18n.vi.Keys) | Sort-Object) -join ','
        foreach ($lang in 'en', 'zh', 'ru') {
            (@($i18n[$lang].Keys) | Sort-Object) -join ',' | Should -Be $viKeys -Because "ngôn ngữ '$lang' phải đủ khóa như 'vi'"
        }
    }
}

Describe 'Limit-LicText' {
    It 'chuỗi ngắn giữ nguyên' {
        Limit-LicText -Text 'hello' | Should -Be 'hello'
    }
    It 'gộp khoảng trắng thừa và trim' {
        Limit-LicText -Text "  a`t`tb   c  " | Should -Be 'a b c'
    }
    It 'cắt chuỗi dài kèm dấu …' {
        $r = Limit-LicText -Text ('x' * 200) -Max 50
        $r.Length | Should -Be 50
        $r | Should -Match '…$'
    }
}

Describe 'Test-LicKms38' {
    BeforeAll {
        function New-KmsProduct([double]$Minutes) {
            [PSCustomObject]@{
                Name = 'Windows(R), Professional edition'
                LicenseStatus = 1
                Description = 'Windows(R) Operating System, VOLUME_KMSCLIENT channel'
                GracePeriodRemaining = $Minutes
            }
        }
    }
    It 'không có giấy phép KMS nào -> hợp lệ' {
        (Test-LicKms38 -Products @()).Bad | Should -BeFalse
    }
    It 'giấy phép Retail (không phải KMSCLIENT) -> hợp lệ' {
        $p = [PSCustomObject]@{ Name = 'Windows(R), Pro'; LicenseStatus = 1
            Description = 'Windows(R) Operating System, RETAIL channel'; GracePeriodRemaining = 0 }
        (Test-LicKms38 -Products @($p)).Bad | Should -BeFalse
    }
    It 'hạn KMS 180 ngày chuẩn -> hợp lệ' {
        (Test-LicKms38 -Products @(New-KmsProduct 259200)).Bad | Should -BeFalse
    }
    It 'hạn KMS đẩy tới ~2038 -> phát hiện KMS38' {
        (Test-LicKms38 -Products @(New-KmsProduct 6300000)).Bad | Should -BeTrue
    }
    It 'kích hoạt vĩnh viễn trên kênh KMS -> không hợp lệ (TSforge)' {
        (Test-LicKms38 -Products @(New-KmsProduct 0)).Bad | Should -BeTrue
    }
}

Describe 'Test-LicChannelBios' {
    BeforeAll {
        function New-OsProduct([string]$Channel, [string]$Desc) {
            [PSCustomObject]@{ Name = 'Windows(R), Professional edition'; LicenseStatus = 1
                ProductKeyChannel = $Channel; Description = $Desc }
        }
        $svcWithOem = [PSCustomObject]@{
            OA3xOriginalProductKey = 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
            OA3xOriginalProductKeyDescription = 'Win 11 RTM Core OEM:DM'
        }
        $svcNoOem = [PSCustomObject]@{ OA3xOriginalProductKey = ''; OA3xOriginalProductKeyDescription = '' }
    }
    It 'BIOS có key OEM nhưng kích hoạt kênh Volume -> không hợp lệ' {
        $os = New-OsProduct 'Volume:GVLK' 'Windows(R) Operating System, VOLUME_KMSCLIENT channel'
        (Test-LicChannelBios -Products @($os) -Service $svcWithOem -PartOfDomain $false).Bad | Should -BeTrue
    }
    It 'kênh Volume trên máy ngoài domain -> không hợp lệ' {
        $os = New-OsProduct 'Volume:GVLK' 'Windows(R) Operating System, VOLUME_KMSCLIENT channel'
        (Test-LicChannelBios -Products @($os) -Service $svcNoOem -PartOfDomain $false).Bad | Should -BeTrue
    }
    It 'kênh Volume trong domain công ty -> hợp lệ' {
        $os = New-OsProduct 'Volume:GVLK' 'Windows(R) Operating System, VOLUME_KMSCLIENT channel'
        (Test-LicChannelBios -Products @($os) -Service $svcNoOem -PartOfDomain $true).Bad | Should -BeFalse
    }
    It 'kênh Retail không BIOS key -> hợp lệ' {
        $os = New-OsProduct 'Retail' 'Windows(R) Operating System, RETAIL channel'
        (Test-LicChannelBios -Products @($os) -Service $svcNoOem -PartOfDomain $false).Bad | Should -BeFalse
    }
    It 'kênh OEM khớp BIOS key -> hợp lệ' {
        $os = New-OsProduct 'OEM:DM' 'Windows(R) Operating System, OEM_DM channel'
        (Test-LicChannelBios -Products @($os) -Service $svcWithOem -PartOfDomain $false).Bad | Should -BeFalse
    }
    It 'thiếu ProductKeyChannel -> rơi về đọc kênh từ Description' {
        $os = [PSCustomObject]@{ Name = 'Windows(R), Pro'; LicenseStatus = 1
            Description = 'Windows(R) Operating System, VOLUME_KMSCLIENT channel' }
        (Test-LicChannelBios -Products @($os) -Service $svcNoOem -PartOfDomain $false).Bad | Should -BeTrue
    }
    It 'không có giấy phép hoạt động -> không báo xấu, không ném lỗi' {
        (Test-LicChannelBios -Products @() -Service $svcNoOem -PartOfDomain $false).Bad | Should -BeFalse
    }
}

Describe 'Get-LicVerdict' {
    It 'SLWGA chính hãng + đã kích hoạt + 0 phát hiện -> genuine' {
        Get-LicVerdict -GenuineState 0 -LicenseStatus 1 -BadCount 0 | Should -Be 'genuine'
    }
    It 'chính hãng nhưng còn dấu vết tool lậu -> traces' {
        Get-LicVerdict -GenuineState 0 -LicenseStatus 1 -BadCount 3 | Should -Be 'traces'
    }
    It 'giấy phép bị can thiệp (Tampered) -> not-genuine kể cả khi LicenseStatus = 1' {
        Get-LicVerdict -GenuineState 2 -LicenseStatus 1 -BadCount 0 | Should -Be 'not-genuine'
    }
    It 'giấy phép không hợp lệ (Invalid) -> not-genuine' {
        Get-LicVerdict -GenuineState 1 -LicenseStatus 1 -BadCount 0 | Should -Be 'not-genuine'
    }
    It 'chưa kích hoạt (Notification) -> not-genuine' {
        Get-LicVerdict -GenuineState 3 -LicenseStatus 5 -BadCount 0 | Should -Be 'not-genuine'
    }
    It 'SLWGA offline nhưng đã kích hoạt -> rơi về trạng thái kích hoạt = genuine' {
        Get-LicVerdict -GenuineState 3 -LicenseStatus 1 -BadCount 0 | Should -Be 'genuine'
    }
    It 'API lỗi nhưng đã kích hoạt + có dấu vết -> traces' {
        Get-LicVerdict -GenuineState -1 -LicenseStatus 1 -BadCount 1 | Should -Be 'traces'
    }
    It 'SLWGA chính hãng nhưng không đọc được WMI (status -1) -> tin SLWGA = genuine' {
        Get-LicVerdict -GenuineState 0 -LicenseStatus -1 -BadCount 0 | Should -Be 'genuine'
    }
    It 'không đọc được cả hai nguồn -> not-genuine (an toàn)' {
        Get-LicVerdict -GenuineState -1 -LicenseStatus -1 -BadCount 0 | Should -Be 'not-genuine'
    }
}

Describe 'Regression issue #1: cấm GetNewClosure' {
    It 'WinTrash.ps1 không chứa lời gọi .GetNewClosure()' {
        # GetNewClosure buộc scriptblock vào dynamic module; tra cứu lệnh trong module
        # chỉ đi module -> global, BỎ QUA script scope. Chạy script kiểu `.\WinTrash.ps1`
        # (hàm nằm ở script scope, khác với -File đặt hàm vào global) thì mọi hàm của
        # script "biến mất" bên trong closure -> "Write-StatusLine is not recognized"
        # ngay giữa lúc dọn (issue #1). Block thường đã giữ nguyên session state, đủ dùng.
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $PSScriptRoot '..\WinTrash.ps1'), [ref]$tokens, [ref]$errors)
        $calls = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Member -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
            $node.Member.Value -eq 'GetNewClosure'
        }, $true)
        $calls | Should -HaveCount 0
    }
}
