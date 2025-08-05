<#
.SYNOPSIS
    An advanced, modern GUI for Windows driver management and updates with a toolbar UI.
.DESCRIPTION
    A comprehensive, self-contained PowerShell script featuring a rich, dark-themed WPF user interface.
    It provides tools to find and install driver updates, view all installed drivers, perform backups,
    and see detailed system information. This version is fully compatible with `irm | iex`.
.NOTES
    Author: Your Name / AI Assistant
    Version: 3.4 (Toolbar UI Edition)
    Requires: PowerShell 5.1+ on Windows 10/11.
    MUST be run as Administrator for full functionality.

.HOW TO RUN
    1. Open PowerShell AS AN ADMINISTRATOR.
    2. Paste and run the following command:
       irm https://raw.githubusercontent.com/your-username/your-repo/main/DriverUpdaterModernGUI.ps1 | iex
#>

#region Preamble & Admin Check
# Exit if not running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges are required for this application to function correctly. Please re-launch PowerShell as an Administrator."
    Read-Host "Press Enter to exit..."
    exit
}

# Suppress verbose progress bars from cmdlets
$ProgressPreference = 'SilentlyContinue'
#endregion

function Start-DriverTool {
    #region Prerequisites and Assembly Loading
    try {
        Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms
    }
    catch {
        Write-Error "Failed to load required .NET assemblies. This script is designed for Windows 10/11."
        return
    }
    #endregion

    #region XAML UI Definition
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Advanced Driver Tool v3.4" Height="700" Width="950" MinHeight="600" MinWidth="800"
        WindowStartupLocation="CenterScreen" WindowStyle="SingleBorderWindow"
        Background="#FF2D2D30">
    <Window.Resources>
        <!-- Modern Dark Theme Colors -->
        <SolidColorBrush x:Key="BgColor" Color="#FF2D2D30"/>
        <SolidColorBrush x:Key="PrimaryBgColor" Color="#FF3F3F46"/>
        <SolidColorBrush x:Key="AccentColor" Color="#FF007ACC"/>
        <SolidColorBrush x:Key="TextColor" Color="#FFF1F1F1"/>
        <SolidColorBrush x:Key="FadedTextColor" Color="#FF9E9E9E"/>

        <!-- Style for all Buttons -->
        <Style x:Key="DefaultButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentColor}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FF005A9E"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#FF555555"/>
                    <Setter Property="Foreground" Value="#FF999999"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Style for Toolbar Buttons -->
        <Style x:Key="ToolBarButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource TextColor}"/>
            <Setter Property="Padding" Value="8"/>
            <Setter Property="Margin" Value="2"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FF555555"/>
                    <Setter Property="BorderBrush" Value="#FF6B6B6B"/>
                </Trigger>
                 <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="#FF6A6A6A"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Style for the TabControl -->
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="{StaticResource BgColor}"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Background" Value="{StaticResource PrimaryBgColor}"/>
            <Setter Property="Foreground" Value="{StaticResource TextColor}"/>
            <Setter Property="Padding" Value="15,10"/>
            <Setter Property="Template">
                 <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" BorderThickness="0,0,0,2" BorderBrush="Transparent">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="BorderBrush" Value="{StaticResource AccentColor}" />
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                             <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="BorderBrush" Value="{StaticResource AccentColor}" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Style for the ToolBar -->
        <Style TargetType="ToolBar">
            <Setter Property="Background" Value="{StaticResource PrimaryBgColor}"/>
        </Style>
        <Style TargetType="ToolBarTray">
            <Setter Property="Background" Value="{StaticResource PrimaryBgColor}"/>
        </Style>

        <!-- Style for the DataGrid -->
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="{StaticResource PrimaryBgColor}"/>
            <Setter Property="Foreground" Value="{StaticResource TextColor}"/>
            <Setter Property="BorderBrush" Value="#FF555555"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#FF555555"/>
            <Setter Property="VerticalGridLinesBrush" Value="#FF555555"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TabControl Grid.Row="0">
            <!-- Update Center Tab -->
            <TabItem Header="Update Center">
                <Grid Background="{StaticResource PrimaryBgColor}">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <ToolBarTray Grid.Row="0">
                        <ToolBar>
                            <Button x:Name="ScanButton" ToolTip="Scan for Updates" Style="{StaticResource ToolBarButtonStyle}">
                                <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="20" Text="&#xE721;"/>
                            </Button>
                            <Button x:Name="InstallButton" IsEnabled="False" ToolTip="Install Selected Updates" Style="{StaticResource ToolBarButtonStyle}">
                                <StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE896;" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock Text="Install Selected"/></StackPanel>
                            </Button>
                            <Separator/>
                            <CheckBox x:Name="SelectAllCheckBox" Content="Select All/None" Foreground="{StaticResource TextColor}" VerticalAlignment="Center" Margin="10,0,0,0"/>
                        </ToolBar>
                    </ToolBarTray>
                    
                    <DataGrid x:Name="UpdateDataGrid" Grid.Row="1" Margin="5" AutoGenerateColumns="False" IsReadOnly="True" CanUserSortColumns="True" SelectionMode="Single">
                        <DataGrid.Columns>
                            <DataGridTemplateColumn Header="Install" Width="SizeToCells">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate><CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center"/></DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                            <DataGridTextColumn Header="Driver Name" Binding="{Binding Title}" Width="*"/>
                            <DataGridTextColumn Header="Size (MB)" Binding="{Binding SizeMB}" Width="Auto"/>
                            <DataGridTextColumn Header="KB Article" Binding="{Binding KB}" Width="Auto"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>

            <!-- Driver Manager Tab -->
            <TabItem Header="Driver Manager">
                <Grid Background="{StaticResource PrimaryBgColor}">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                     <ToolBarTray Grid.Row="0">
                        <ToolBar>
                             <Button x:Name="ListDriversButton" ToolTip="List Installed Drivers" Style="{StaticResource ToolBarButtonStyle}">
                                <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="20" Text="&#xE71D;"/>
                            </Button>
                            <Button x:Name="BackupDriversButton" IsEnabled="False" ToolTip="Backup All 3rd-Party Drivers" Style="{StaticResource ToolBarButtonStyle}">
                                <StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE790;" VerticalAlignment="Center" Margin="0,0,8,0"/><TextBlock Text="Backup Drivers"/></StackPanel>
                            </Button>
                             <Separator/>
                            <TextBlock Text="Filter:" Foreground="{StaticResource TextColor}" VerticalAlignment="Center" Margin="10,0,5,0"/>
                            <TextBox x:Name="FilterTextBox" Width="200" VerticalAlignment="Center" Background="#FF555555" Foreground="White" BorderThickness="1" BorderBrush="#FF6B6B6B"/>
                        </ToolBar>
                    </ToolBarTray>
                    
                    <DataGrid x:Name="DriverManagerDataGrid" Grid.Row="1" Margin="5" AutoGenerateColumns="False" IsReadOnly="True" CanUserSortColumns="True">
                         <DataGrid.Columns>
                            <DataGridTextColumn Header="Driver" Binding="{Binding FriendlyName}" Width="*"/>
                            <DataGridTextColumn Header="Manufacturer" Binding="{Binding Manufacturer}" Width="200"/>
                            <DataGridTextColumn Header="Version" Binding="{Binding DriverVersion}" Width="150"/>
                             <DataGridTextColumn Header="Date" Binding="{Binding DriverDate, StringFormat={}{0:yyyy-MM-dd}}" Width="100"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>

            <!-- System Info Tab -->
            <TabItem Header="System Information">
                 <Grid Background="{StaticResource PrimaryBgColor}" Margin="5">
                     <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="SystemInfoPanel" Margin="20"/>
                     </ScrollViewer>
                 </Grid>
            </TabItem>
            
            <!-- Settings & About Tab -->
            <TabItem Header="Settings &amp; About">
                 <Grid Background="{StaticResource PrimaryBgColor}" Margin="5">
                    <StackPanel Margin="20">
                        <TextBlock Text="Utilities" FontSize="18" FontWeight="Bold" Foreground="White" Margin="0,0,0,10"/>
                        <Button x:Name="ClearCacheButton" Content="Clear Windows Update Cache" Style="{StaticResource DefaultButtonStyle}" HorizontalAlignment="Left" Margin="0,0,0,20"/>
                        <TextBlock Text="About" FontSize="18" FontWeight="Bold" Foreground="White" Margin="0,10,0,10"/>
                        <TextBlock TextWrapping="Wrap" Foreground="{StaticResource TextColor}" LineHeight="20">
                            <Run FontWeight="Bold">Advanced Driver Tool v3.4</Run><LineBreak/>
                            A modern, all-in-one utility for managing your PC's drivers. This tool safely uses the official Windows Update service to find and install WHQL-certified drivers.<LineBreak/>
                            <LineBreak/>
                            <Run FontWeight="Bold">Features:</Run><LineBreak/>
                            - Scan for and install driver updates.<LineBreak/>
                            - View, filter, and sort all installed third-party drivers.<LineBreak/>
                            - Back up drivers to an external location, ideal for OS reinstalls.<LineBreak/>
                            - View detailed system hardware information.<LineBreak/>
                            - Run as Administrator for full functionality.
                        </TextBlock>
                    </StackPanel>
                 </Grid>
            </TabItem>
        </TabControl>

        <!-- Status Bar -->
        <StatusBar Grid.Row="1" Background="{StaticResource AccentColor}" Foreground="White">
            <StatusBarItem>
                <TextBlock x:Name="StatusText" Text="Ready"/>
            </StatusBarItem>
            <StatusBarItem HorizontalAlignment="Right">
                <TextBlock x:Name="AdminStatusText" Text="Admin Privileges: Yes"/>
            </StatusBarItem>
        </StatusBar>
        
        <!-- Progress Overlay -->
        <Grid x:Name="ProgressOverlay" Grid.RowSpan="2" Background="#80000000" Visibility="Collapsed">
            <Border HorizontalAlignment="Center" VerticalAlignment="Center" Background="{StaticResource PrimaryBgColor}" CornerRadius="5" Padding="30">
                <StackPanel>
                    <ProgressBar IsIndeterminate="True" Width="300" Height="20"/>
                    <TextBlock x:Name="ProgressText" Text="Working..." Foreground="White" FontSize="16" HorizontalAlignment="Center" Margin="0,15,0,0"/>
                </StackPanel>
            </Border>
        </Grid>
    </Grid>
</Window>
"@
    #endregion

    #region UI Initialization and Control Wiring
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Wire up controls
    $controls = @{}
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'x:Name')]]") | ForEach-Object {
        $controls[$_.Name] = $window.FindName($_.Name)
    }

    # Data Collections for DataGrids
    $script:updateCollection = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
    $controls.UpdateDataGrid.ItemsSource = $script:updateCollection
    
    $script:allDriversCollection = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
    $script:driversView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($script:allDriversCollection)
    $controls.DriverManagerDataGrid.ItemsSource = $script:driversView
    #endregion

    #region Helper Functions
    function Update-Status { param([string]$Message) $window.Dispatcher.Invoke({ $controls.StatusText.Text = $Message }) }
    function Set-ProgressState {
        param([bool]$IsActive, [string]$Message = "Working...")
        $window.Dispatcher.Invoke({
            $controls.ProgressText.Text = $Message
            $controls.ProgressOverlay.Visibility = if ($IsActive) { 'Visible' } else { 'Collapsed' }
        })
    }

    function Show-MessageBox { param([string]$Text, [string]$Title, [string]$Icon = "Information") 
        $window.Dispatcher.Invoke({ [System.Windows.MessageBox]::Show($window, $Text, $Title, 'OK', $Icon) }) | Out-Null
    }

    function Ensure-PSWindowsUpdate {
        Update-Status "Checking for 'PSWindowsUpdate' module..."
        if (Get-Module -ListAvailable -Name PSWindowsUpdate) { return $true }

        Set-ProgressState -IsActive $true -Message "Installing required module..."
        try {
            Install-Module PSWindowsUpdate -Force -AcceptLicense -Scope CurrentUser -ErrorAction Stop
            Update-Status "'PSWindowsUpdate' module installed successfully."
            return $true
        } catch {
            Show-MessageBox "Failed to install 'PSWindowsUpdate' module. Check your internet connection." "Module Error" "Error"
            return $false
        } finally { Set-ProgressState -IsActive $false }
    }
    #endregion

    #region Core Logic and Event Handlers
    # --- Update Center ---
    $controls.ScanButton.add_Click({
        if (-not (Ensure-PSWindowsUpdate)) { return }
        Set-ProgressState -IsActive $true -Message "Scanning for driver updates..."
        Update-Status "Scanning... this may take a few minutes."
        $script:updateCollection.Clear(); $controls.InstallButton.IsEnabled = $false
        
        $script:currentJob = Start-Job -ScriptBlock { Import-Module PSWindowsUpdate; Get-WindowsUpdate -CategoryIDs '0fa1201d-4330-4fa8-8ae9-b877473b6441' -ErrorAction SilentlyContinue }
        $script:currentTimer = New-Object System.Windows.Threading.DispatcherTimer; $script:currentTimer.Interval = [TimeSpan]::FromSeconds(1)
        $script:currentTimer.add_Tick({
            if ($script:currentJob.State -ne 'Running') {
                $script:currentTimer.Stop()
                $updates = Receive-Job $script:currentJob; Remove-Job $script:currentJob
                if ($null -eq $updates -or $updates.Count -eq 0) {
                    Update-Status "No new driver updates found. Your system is up to date!"
                } else {
                    $updates | ForEach-Object {
                        $script:updateCollection.Add([PSCustomObject]@{ IsSelected = $false; Title = $_.Title; SizeMB = "{0:N2}" -f ($_.Size / 1MB); KB = $_.KB; UpdateObject = $_ })
                    }
                    Update-Status "Found $($updates.Count) driver update(s)."
                }
                Set-ProgressState -IsActive $false
            }
        }); $script:currentTimer.Start()
    })

    $controls.InstallButton.add_Click({
        $updatesToInstall = $script:updateCollection | Where-Object { $_.IsSelected }
        if ($updatesToInstall.Count -eq 0) { return }
        
        $confirm = [System.Windows.MessageBox]::Show($window, "This will install $($updatesToInstall.Count) driver(s). The system may reboot automatically. Proceed?", "Confirm Installation", 'YesNo', 'Warning')
        if ($confirm -ne 'Yes') { Update-Status "Installation cancelled."; return }

        Set-ProgressState -IsActive $true -Message "Installing selected updates..."
        Update-Status "Installing..."
        $originalUpdates = $updatesToInstall.UpdateObject

        $script:currentJob = Start-Job -ScriptBlock { param($updates) Import-Module PSWindowsUpdate; Install-WindowsUpdate -InputObject $updates -AcceptAll -AutoReboot } -ArgumentList (,$originalUpdates)
        $script:currentTimer = New-Object System.Windows.Threading.DispatcherTimer; $script:currentTimer.Interval = [TimeSpan]::FromSeconds(1)
        $script:currentTimer.add_Tick({
            if ($script:currentJob.State -ne 'Running') {
                $script:currentTimer.Stop(); $result = Receive-Job $script:currentJob; Remove-Job $script:currentJob
                Set-ProgressState -IsActive $false
                Update-Status "Installation finished. A reboot may be pending. Please scan again after reboot."
                $script:updateCollection.Clear(); $controls.InstallButton.IsEnabled = $false
            }
        }); $script:currentTimer.Start()
    })

    $controls.UpdateDataGrid.add_MouseUp({ 
        Start-Sleep -Milliseconds 50
        $controls.InstallButton.IsEnabled = ($script:updateCollection | Where-Object { $_.IsSelected }).Count -gt 0
    })

    $controls.SelectAllCheckBox.add_Click({
        $isChecked = $controls.SelectAllCheckBox.IsChecked
        $script:updateCollection | ForEach-Object { $_.IsSelected = $isChecked }
        $controls.InstallButton.IsEnabled = ($isChecked -and $script:updateCollection.Count -gt 0)
    })

    # --- Driver Manager ---
    $controls.ListDriversButton.add_Click({
        Set-ProgressState -IsActive $true -Message "Gathering driver information..."
        Update-Status "Listing installed drivers..."
        $script:allDriversCollection.Clear(); $controls.BackupDriversButton.IsEnabled = $false

        $script:currentJob = Start-Job -ScriptBlock { Get-PnpDevice | Where-Object { $_.DriverVersion -and $_.Manufacturer -ne "Microsoft" } | Select-Object FriendlyName, Manufacturer, DriverVersion, DriverDate }
        $script:currentTimer = New-Object System.Windows.Threading.DispatcherTimer; $script:currentTimer.Interval = [TimeSpan]::fromMilliseconds(500)
        $script:currentTimer.add_Tick({
            if ($script:currentJob.State -ne 'Running') {
                $script:currentTimer.Stop()
                $drivers = Receive-Job $script:currentJob; Remove-Job $script:currentJob
                $drivers | ForEach-Object { $script:allDriversCollection.Add($_) }
                Update-Status "Found $($drivers.Count) third-party drivers."
                $controls.BackupDriversButton.IsEnabled = ($drivers.Count -gt 0)
                Set-ProgressState -IsActive $false
            }
        }); $script:currentTimer.Start()
    })

    $controls.FilterTextBox.add_TextChanged({
        $filterText = $controls.FilterTextBox.Text
        $script:driversView.Filter = { param($item) $item.FriendlyName -like "*$filterText*" -or $item.Manufacturer -like "*$filterText*" }
    })

    $controls.BackupDriversButton.add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select a folder to save the driver backup"
        if ($dialog.ShowDialog() -eq "OK") {
            $path = $dialog.SelectedPath
            Set-ProgressState -IsActive $true -Message "Backing up drivers to $path..."
            Update-Status "Exporting drivers..."

            $script:currentJob = Start-Job -ScriptBlock { param($path) Export-WindowsDriver -Online -Destination $path } -ArgumentList $path
            $script:currentTimer = New-Object System.Windows.Threading.DispatcherTimer; $script:currentTimer.Interval = [TimeSpan]::FromSeconds(1)
            $script:currentTimer.add_Tick({
                if ($script:currentJob.State -ne 'Running') {
                    $script:currentTimer.Stop(); $result = Receive-Job $script:currentJob; Remove-Job $script:currentJob
                    Set-ProgressState -IsActive $false
                    Update-Status "Driver backup completed successfully."
                    Show-MessageBox "All third-party drivers have been backed up to:`n$path" "Backup Complete"
                }
            }); $script:currentTimer.Start()
        }
    })

    # --- System Info ---
    function Populate-SystemInfo {
        $panel = $controls.SystemInfoPanel
        $panel.Children.Clear()

        function Add-Heading { param($Text) $tb = New-Object System.Windows.Controls.TextBlock; $tb.Text = $Text; $tb.FontSize = 16; $tb.FontWeight = [System.Windows.FontWeights]::Bold; $tb.Foreground = $window.FindResource('TextColor'); $tb.Margin = "0,15,0,5"; $panel.Children.Add($tb) }
        function Add-Item { param($Key, $Value) if (-not [string]::IsNullOrWhiteSpace($Value)) { $tb = New-Object System.Windows.Controls.TextBlock; $tb.Text = "$Key`: $Value"; $tb.Foreground = $window.FindResource('FadedTextColor'); $tb.Margin = "10,2,0,2"; $panel.Children.Add($tb) } }

        Add-Heading 'Operating System'; $os = Get-CimInstance -ClassName Win32_OperatingSystem; Add-Item 'Name' $os.Caption; Add-Item 'Version' $os.Version; Add-Item 'Build' $os.BuildNumber
        Add-Heading 'Processor'; $cpu = Get-CimInstance -ClassName Win32_Processor; Add-Item 'Name' $cpu.Name; Add-Item 'Cores' $cpu.NumberOfCores; Add-Item 'Threads' $cpu.NumberOfLogicalProcessors
        Add-Heading 'Graphics Card'; $gpus = Get-CimInstance -ClassName Win32_VideoController; foreach ($gpu in $gpus) { Add-Item $gpu.Name "$([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB" }
        Add-Heading 'Memory'; $mem = Get-CimInstance -ClassName Win32_ComputerSystem; Add-Item 'Total RAM' "$([math]::Round($mem.TotalPhysicalMemory / 1GB, 2)) GB"
        Add-Heading 'Motherboard'; $board = Get-CimInstance -ClassName Win32_BaseBoard; Add-Item 'Manufacturer' $board.Manufacturer; Add-Item 'Product' $board.Product
        Add-Heading 'BIOS'; $bios = Get-CimInstance -ClassName Win32_BIOS; Add-Item 'Manufacturer' $bios.Manufacturer; Add-Item 'Version' $bios.SMBIOSBIOSVersion
    }
    Populate-SystemInfo

    # --- Settings Tab ---
    $controls.ClearCacheButton.add_Click({
        if (-not (Ensure-PSWindowsUpdate)) { return }
        $confirm = [System.Windows.MessageBox]::Show($window, "This will stop the Windows Update service and delete its cache files. This can help resolve update issues. Proceed?", "Confirm Cache Clear", 'YesNo', 'Warning')
        if ($confirm -ne 'Yes') { return }
        
        Set-ProgressState -IsActive $true -Message "Resetting Windows Update components..."
        Update-Status "Clearing cache..."
        
        $script:currentJob = Start-Job -ScriptBlock { Import-Module PSWindowsUpdate; Reset-WUComponents -ErrorAction SilentlyContinue }
        $script:currentTimer = New-Object System.Windows.Threading.DispatcherTimer; $script:currentTimer.Interval = [TimeSpan]::FromSeconds(1)
        $script:currentTimer.add_Tick({
            if ($script:currentJob.State -ne 'Running') {
                $script:currentTimer.Stop(); $result = Receive-Job $script:currentJob; Remove-Job $script:currentJob
                Set-ProgressState -IsActive $false
                Update-Status "Windows Update cache cleared successfully."
            }
        }); $script:currentTimer.Start()
    })
    #endregion
    
    # Show the window
    Update-Status "Ready"
    $window.ShowDialog() | Out-Null
}

# Execute Main Function
Start-DriverTool
