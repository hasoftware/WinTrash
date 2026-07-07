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
