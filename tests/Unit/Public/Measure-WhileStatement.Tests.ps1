$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName
$script:ModuleName = $ProjectName

. $PSScriptRoot\Get-AstFromDefinition.ps1

$ModuleUnderTest = Import-Module $ProjectName -PassThru
$localizedData = &$ModuleUnderTest { $Script:LocalizedData }
$modulePath = $ModuleUnderTest.Path

Describe 'Measure-WhileStatement' {
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.WhileStatementAst'
            $ruleName = 'Measure-WhileStatement'
        }

        Context 'When While-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0) {
                            $i--
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-WhileStatement -WhileStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceNotOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When While-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        { $i--
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-WhileStatement -WhileStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When While-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        {

                            $i--
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-WhileStatement -WhileStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-WhileStatement"
        }

        Context 'When While-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0) {
                            $i--
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceNotOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When While-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        { $i--
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When While-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        {

                            $i--
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.WhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When While-statement follows style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        $i = 10

                        while ($i -gt 0)
                        {
                            $i--
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }
    }
}
