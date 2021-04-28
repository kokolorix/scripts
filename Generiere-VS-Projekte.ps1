
param($groupPfad = "V:\Dev\Work\Test.groupproj")
Clear-Host
Set-Location (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)

$groupPfad = Get-Item -Path $groupPfad;
$groupDoc = New-Object System.Xml.XmlDocument;
$groupDoc.Load($groupPfad);
$groupProj = $groupDoc.DocumentElement;
$script:projCnt = $groupProj.ItemGroup.Projects.Count;
$script:projNr = 0;

$script:projectPaths = @{"PREBUILDEVENT" = ".\Tools\PreBuildEvent.vcxproj"; "POSTBUILDEVENT" = ".\Tools\PostBuildEvent.vcxproj";};

$projectGuids = @{"PREBUILDEVENT" = "{E554EEA1-9A02-4865-8217-4083EA81E6E6}"; "POSTBUILDEVENT" = "{D0082ED5-2826-456D-A8C4-ECF5CB880BDB}";}

# if($script:projCnt -le 99)
# {$projectNames = @{"PREBUILDEVENT" = "00-PreBuildEvent"; "POSTBUILDEVENT" = "99-PostBuildEvent";}}
# else
# {$projectNames = @{"PREBUILDEVENT" = "000-PreBuildEvent"; "POSTBUILDEVENT" = "999-PostBuildEvent";}}
$projectNames = @{"PREBUILDEVENT" = "PreBuildEvent"; "POSTBUILDEVENT" = "PostBuildEvent";}

foreach ( $itemGroup in $groupProj.ItemGroup)
{
	foreach ($prj in $itemGroup.Projects)
 	{
		$vfolders = @{}

		if (Test-Path $prj.Include) {$cbprojPfad = $prj.Include; } else {$cbprojPfad = Join-Path -Path $groupPfad.Directory -ChildPath $prj.Include; }
		$cbproj = [Xml](Get-Content -Path $cbprojPfad);
		$cbproj.Project.PropertyGroup.SanitizedProjectName | ForEach-Object { if ($_) {  $name = $_ } }
		$cbproj.Project.PropertyGroup.ProjectGuid | ForEach-Object { if ($_) {  $guid = $_ } }
		$cbproj.Project.PropertyGroup | ForEach-Object { if ($_ -and ($_.Condition -eq "'`$(Base)'!=''")) { $include = $_.IncludePath } }
		# $cbproj.Project.PropertyGroup | ForEach-Object { if ($_) { $include = $_.IncludePath } }

		$projectGuids.Add($name.ToUpper(), $guid);

		function processVFolder ( $vfolder, $pname )
		{
			if ($pname) {$vname = $pname + "\" + $vfolder.name} else {$vname = $vfolder.name}
			$vid = $vfolder.ID
			# "$vname = $vid" | Out-Host
			$vfolders.Add($vid, $vname)
			foreach ($vfolder in $vfolder.VFOLDER)
			{
				processVFolder -vfolder $vfolder -pname $vname
			}
		}      
		foreach ($vfolder in $cbproj.Project.ProjectExtensions.BorlandProject.'CPlusPlusBuilder.Personality'.VFOLDERS.VFOLDER)
		{
			processVFolder -vfolder $vfolder
		}
		$vcxfilter = New-Object System.Xml.XmlDocument;
		$vcxfilter.InnerXml = (Get-Content -Path "vs_template.vcxproj.filters")
		$fproject = $vcxfilter.Project;
		$fitemGroup1 = $fproject.AppendChild($vcxfilter.CreateElement("ItemGroup", $fproject.NamespaceURI))
		$fitemGroup2 = $fproject.AppendChild($vcxfilter.CreateElement("ItemGroup", $fproject.NamespaceURI))
		$fitemGroup3 = $fproject.AppendChild($vcxfilter.CreateElement("ItemGroup", $fproject.NamespaceURI));
		foreach ($itm in $vfolders.GetEnumerator())
		{
			$filter = $fitemGroup1.AppendChild($vcxfilter.CreateElement("Filter", $fproject.NamespaceURI))
			$filter.SetAttribute("Include", $itm.Value);
			$id = $filter.AppendChild($vcxfilter.CreateElement("UniqueIdentifier", $fproject.NamespaceURI))
			$id.InnerText = $itm.Key            
		}
		
		$vcxproj = New-Object System.Xml.XmlDocument;
		$script:projNr += 1;

		# if($script:projCnt -le 99)
		# {$projctName = ("{0:D2}-{1}" -f $script:projNr, $name);}
		# else
		# {$projctName = ("{0:D3}-{1}" -f $script:projNr, $name);}
		$projctName = $name;

		$projectNames.Add($name.ToUpper(), $projctName);
		$script:projectPaths.Add($name.ToUpper(), [System.IO.Path]::ChangeExtension($cbprojPfad, ".vcxproj"));
		
		$vcxproj.InnerXml = (Get-Content -Path "vs_template.vcxproj") -f $name, $guid, $include, $projctName;
		$project = $vcxproj.Project;
		$itemGroup1 = $project.AppendChild($vcxproj.CreateElement("ItemGroup", $project.NamespaceURI));
		$itemGroup2 = $project.AppendChild($vcxproj.CreateElement("ItemGroup", $project.NamespaceURI));

		$item = $itemGroup1.AppendChild($vcxproj.CreateElement("None", $project.NamespaceURI));
		$item.SetAttribute("Include", (Split-Path -Path $cbprojPfad -Leaf));
      
		$script:addedItems = @();      
		function AddItem ($cbprojItem) 
		{
			if(-not $cbprojItem) { Return; }
			if ($script:addedItems -contains $cbprojItem.Include) { Return; }
			if ([System.IO.Path]::GetExtension($cbprojItem.Include) -eq ".h") {$element = "ClInclude"} else {$element = "ClCompile"};

			$item = $itemGroup1.AppendChild($vcxproj.CreateElement("ClCompile", $project.NamespaceURI));
			$item.SetAttribute("Include", $cbprojItem.Include);
			$fitem = $fitemGroup2.AppendChild($vcxfilter.CreateElement("ClCompile", $fproject.NamespaceURI))
			$fitem.SetAttribute("Include", $cbprojItem.Include);
			$script:addedItems += $cbprojItem.Include;
			if ($cbprojItem.VirtualFolder)
			{
				$fid = $cbprojItem.VirtualFolder
				$fname = $vfolders[$fid];
				$filter = $fitem.AppendChild($vcxfilter.CreateElement("Filter", $fproject.NamespaceURI))
				$filter.InnerText = $fname
			}
			$cppPfad = Join-Path -Path (Split-Path -Path $cbprojPfad -Parent) -ChildPath $cbprojItem.Include;
			$hPfad = [System.IO.Path]::ChangeExtension($cppPfad, ".h");
			if (($cppPfad -ne $hPfad) -and (Test-Path -Path $hPfad))
			{
				if ($script:addedItems -contains [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".h")) { Return; }
				$item = $itemGroup2.AppendChild($vcxproj.CreateElement("ClInclude", $project.NamespaceURI));
				$item.SetAttribute("Include", [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".h"));
				$dependItem = $item.AppendChild($vcxproj.CreateElement("DependentUpon", $project.NamespaceURI));
				$dependItem.InnerText = (Split-Path -Path $cppPfad -Leaf)                  
				$fitem = $fitemGroup3.AppendChild($vcxfilter.CreateElement("ClInclude", $fproject.NamespaceURI))
				$fitem.SetAttribute("Include", [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".h"));
				$script:addedItems += [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".h");
				if ($cbprojItem.VirtualFolder)
				{
					$filter = $fitem.AppendChild($vcxfilter.CreateElement("Filter", $fproject.NamespaceURI))
					$filter.InnerText = $fname
				}
			}            
			$dfmPfad = [System.IO.Path]::ChangeExtension($cppPfad, ".dfm");
			if (Test-Path -Path $dfmPfad)
			{
				if ($script:addedItems -contains [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".dfm")) { Return; }
				$item = $itemGroup2.AppendChild($vcxproj.CreateElement("ClInclude", $project.NamespaceURI));
				$item.SetAttribute("Include", [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".dfm"));                  
				$dependItem = $item.AppendChild($vcxproj.CreateElement("DependentUpon", $project.NamespaceURI));
				$dependItem.InnerText = (Split-Path -Path $cppPfad -Leaf)                  
				$fitem = $fitemGroup3.AppendChild($vcxfilter.CreateElement("ClInclude", $fproject.NamespaceURI))
				$fitem.SetAttribute("Include", [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".dfm"));
				$script:addedItems += [System.IO.Path]::ChangeExtension($cbprojItem.Include, ".dfm");
				if ($cbprojItem.VirtualFolder)
				{
					$filter = $fitem.AppendChild($vcxfilter.CreateElement("Filter", $fproject.NamespaceURI))
					$filter.InnerText = $fname
				}
			} 
		}

		$cbproj.Project.ItemGroup.None | ForEach-Object { AddItem($_); };
		$cbproj.Project.ItemGroup.PCHCompile | ForEach-Object { AddItem($_); };
		$cbproj.Project.ItemGroup.CppCompile | ForEach-Object { AddItem($_); };
		$cbproj.Project.ItemGroup.DelphiCompile | ForEach-Object { AddItem($_); };
		 
		$vcxproj.Project.PropertyGroup | Where-Object {$_.IncludePath} | ForEach-Object {
			$_.IncludePath += $include;
		};
   
		$vcxfilter.Save([System.IO.Path]::ChangeExtension($cbprojPfad, ".vcxproj.filters"));
		$vcxproj.Save([System.IO.Path]::ChangeExtension($cbprojPfad, ".vcxproj"));

		$vcxuserpath = [System.IO.Path]::ChangeExtension($cbprojPfad, ".vcxproj.user");
		if( (Test-Path -Path $vcxuserpath))
		{
			$vcxuser = [IO.File]::ReadAllText($vcxuserpath);
		}

		if( $vcxuser -match 'Generiert=True' )
		{
			$vcxuser = [IO.File]::ReadAllText(".\Tools\vs_template.vcxproj.user");
			$appType = $cbproj.Project.PropertyGroup.AppType[0];
			if (($appType -eq "Application") -or ($appType -eq "Console"))
			{
				$vcxuser = ($vcxuser -replace '\$\(SolutionName\)', $name);
			}
			Set-Content -Path $vcxuserpath -Value $vcxuser;
		}
		
		[System.IO.Path]::ChangeExtension($cbprojPfad, ".vcxproj") | Out-Host
	}
}

$slnPfad = [System.IO.Path]::ChangeExtension($groupPfad, ".sln")
$slnContent = [IO.File]::ReadAllText(".\Tools\vs_template.sln");

$slnGuid = "{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}";
# $slnGuid = "{" + [System.Guid]::NewGuid().ToString().ToUpper() + "}";

# $sb = New-Object -TypeName "System.Text.StringBuilder";

$prjTempl = '
Project("{1}") = "{3}", "{0}", "{2}"
{4}
EndProject';
$prjBuilder = New-Object System.Text.StringBuilder;

$cfgTempl = '
 		{0}.Debug|x86.ActiveCfg = Debug|Win32
 		{0}.Debug|x86.Build.0 = Debug|Win32
 		{0}.Release|x86.ActiveCfg = Release|Win32
 		{0}.Release|x86.Build.0 = Release|Win32';
$cfgBuilder = New-Object System.Text.StringBuilder;

$depTempl = '
	ProjectSection(ProjectDependencies) = postProject
{0}
	EndProjectSection';

foreach ( $itemGroup in $groupProj.ItemGroup)
{
	foreach ($prj in $itemGroup.Projects) 
	{
		$name = [System.IO.Path]::GetFileNameWithoutExtension($prj.Include)
		if (Test-Path $prj.Include) {$cbprojPfad = $prj.Include} else {$cbprojPfad = Join-Path -Path .. -ChildPath $prj.Include -Resolve; }
		$cbproj = [Xml](Get-Content -Path $cbprojPfad);

		$dependencies = @("PREBUILDEVENT");

		$appType = $cbproj.Project.PropertyGroup.AppType[0];
		if ($appType -eq "Package" -or $appType -eq "Library")
		{
			foreach ($PackageImport in $cbproj.Project.ItemGroup.PackageImport)
			{
				$depName = [System.IO.Path]::GetFileNameWithoutExtension($PackageImport.Include);
				if ($projectGuids.ContainsKey($depName.ToUpper()) -and (-not ($dependencies -contains $depName.ToUpper())))
				{
					$dependencies += $depName.ToUpper(); 
				}
			}
			if ($name -eq "BrKomp180") {if ($projectGuids.ContainsKey(("DclOmniLib").ToUpper())) {$dependencies += ("DclOmniLib").ToUpper(); }}
			if ($name -eq "BrServerInProc" -and $projectGuids.ContainsKey(("BrSrvKomp180").ToUpper())) { $dependencies += ("BrSrvKomp180").ToUpper(); }
		}
		if ($appType -ne "Package")
		{
			foreach ($node in $cbproj.Project.PropertyGroup)
			{ 
				if ($node) 
				{
					foreach ($PackageImport in ($node.PackageImports -split ';'))
					{
						$depName = [System.IO.Path]::GetFileNameWithoutExtension($PackageImport);
						if ($projectGuids.ContainsKey($depName.ToUpper()) -and (-not ($dependencies -contains $depName.ToUpper())))
						{
							$dependencies += $depName.ToUpper(); 
						}
					}
				}
			}
		}

		if ($dependencies.Length)
		{
			$depBuilder = New-Object System.Text.StringBuilder;
			foreach ($dep in $dependencies)
			{
				if ($projectGuids.ContainsKey($dep.ToUpper()))
				{
					$depGuid = $projectGuids.Get_Item($dep).ToUpper();
					$depBuilder.AppendLine('		{0} = {0}' -f $depGuid) | Out-Null;
				}
				else
				{
					"Anh�ngikeit '$dep' ist nicht in Solution" | Out-Host
				}
			}
			$dependencyBlock = $depTempl -f $depBuilder.ToString();                  
		}
		else {
			$dependencyBlock = "";
		}

		try {
			$prjGuid = $projectGuids.Get_Item($name.ToUpper()).ToUpper();
			$prjName = $projectNames.Get_Item($name.ToUpper());
			$prjBuilder.Append( ( $prjTempl -f ( [System.IO.Path]::ChangeExtension($prj.Include, ".vcxproj"), $slnGuid, $prjGuid, $prjName, $dependencyBlock ) ) ) | Out-Null;
			$cfgBuilder.Append( ( $cfgTempl -f ( $prjGuid ) ) ) | Out-Null;	
		}
		catch {	
			"$name nicht in Map" | Out-Host
		}
	}
}

$postDepBuilder = New-Object System.Text.StringBuilder;
foreach( $kvp in $projectGuids.GetEnumerator() )
{
	$postDepBuilder.AppendLine('		{0} = {0}' -f $kvp.Value) | Out-Null;	
}

$groups = @{
	"System" = "{CE980630-2981-4D42-ABC8-486AD2F43B84}";
	"Basis" = "{DA032BA8-9A3C-405C-B232-75897BF3F895}";
	"ElektroForm" = "{FCBA432C-8DEF-4E24-8477-A6085B86522A}";
	"InfraDATA" = "{1D35E2C6-87E4-4AC7-B51D-68BFA51C7775}";
	"Tools" = "{0E14D0F6-0812-4311-AA38-3175C2CA712C}";
	"Test" = "{548dd257-9f62-4b1b-9e2d-e0503ab3915b}";
	"M20" = "{6A61C165-CB6B-4C5A-9190-F9FC16EDE40B}";
	"Office" = "{C9C0F2EF-53D5-44B3-B8DD-0812EE2C223F}";
};

$groupGuids = @{};
$groups.GetEnumerator() | ForEach-Object {
	$groupGuids.Add($_.Key.ToUpper(), $_.Value.ToUpper());
}
# $groupGuids = @{
# 	"SYSTEM" = "{CE980630-2981-4D42-ABC8-486AD2F43B84}";
# 	"BASIS" = "{DA032BA8-9A3C-405C-B232-75897BF3F895}";
# 	"ELEKTROFORM" = "{FCBA432C-8DEF-4E24-8477-A6085B86522A}";
# 	"INFRADATA" = "{1D35E2C6-87E4-4AC7-B51D-68BFA51C7775}";
# 	"TOOLS" = "{0E14D0F6-0812-4311-AA38-3175C2CA712C}";
# 	"TEST" = "{548dd257-9f62-4b1b-9e2d-e0503ab3915b}";
# 	"M20" = "{6A61C165-CB6B-4C5A-9190-F9FC16EDE40B}";
# 	"OFFICE" = "{C9C0F2EF-53D5-44B3-B8DD-0812EE2C223F}";
# }

$specialGroup = @{
	"PREBUILDEVENT" = "System";
	"OMNILIB" = "System";
	"TMS180" = "System";
	"DBXSQLITE" = "System";
	"RVPKG180" = "System";
	"RVDBPKG180" = "System";
	"RVACTIONS180" = "System";
	"BRLUA180" = "System";
	"BRRES180" = "System";
	"BRMSOFFICE180" = "System";
	"BRSPELLPKG" = "System";
	"BRCHROMETABS" = "System";
	"BRDRAGDROP" = "System";
	"BLGRAPH10" = "System";
	"BRGRAPH10" = "System";
	"BRGRAPH180" = "System";
	"DCLRVPKG180" = "System";
	"DCLBIGRAPH10" = "System";
	"DCLBRCHROMETABS" = "System";
	"DCLBRCLIKOMP180" = "System";
	"DCLBRGRAPH10" = "System";
	"DCLBRGRAPH180" = "System";
	"DCLBRKOMP180" = "System";
	"DCLBRSRVKOMP180" = "System";
	"DCLOMNILIB" = "System";
	"DCLRVACTIONS180" = "System";
	"DCLRVDBPKG180" = "System";
	"DCLTMS180" = "System";
	"DCLLEISTUNGEN" = "System";
	"POSTBUILDEVENT" = "System";
}

# $groupsBuilder = New-Object System.Text.StringBuilder;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "System", "System", "{CE980630-2981-4D42-ABC8-486AD2F43B84}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Basis", "Basis", "{DA032BA8-9A3C-405C-B232-75897BF3F895}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "ElektroForm", "ElektroForm", "{FCBA432C-8DEF-4E24-8477-A6085B86522A}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "infraDATA", "infraDATA", "{1D35E2C6-87E4-4AC7-B51D-68BFA51C7775}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Tools", "Tools", "{0E14D0F6-0812-4311-AA38-3175C2CA712C}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Test", "Test", "{548dd257-9f62-4b1b-9e2d-e0503ab3915b}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "M20", "M20", "{6A61C165-CB6B-4C5A-9190-F9FC16EDE40B}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;
# $groupsBuilder.AppendLine('Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Office", "Office", "{C9C0F2EF-53D5-44B3-B8DD-0812EE2C223F}"') | Out-Null;
# $groupsBuilder.AppendLine('EndProject') | Out-Null;

$usedGroupGuids = @{}

$nestedBuilder = New-Object System.Text.StringBuilder;
# $groupProj.ItemGroup | ForEach-Object {
# 	$_.Projects | ForEach-Object {

# 	}
# }
$script:projectPaths.GetEnumerator() | ForEach-Object {
	$prjGuid = $projectGuids.Get_Item($_.Key).ToUpper();
	$group = $specialGroup.Get_Item($_.Key);
	if (-not $group) {
		$pathParts = ($_.Value.ToUpper() -split '\\');
		$i = [array]::indexof($pathParts, 'PRODXE7');
		$group = $pathParts[$i + 1];
	}	
	$grpGuid = $groupGuids.Get_Item($group.ToUpper());
	if($grpGuid) {
		if(-not $usedGroupGuids.ContainsKey($grpGuid.ToUpper())){
			$usedGroupGuids.Add($grpGuid.ToUpper(), $group.ToUpper());
		}
		$nestedBuilder.AppendLine(('		{1} = {0}' -f $grpGuid.ToUpper(), $prjGuid)) | Out-Null;	
	}
};

$groupsBuilder = New-Object System.Text.StringBuilder;
$groups.GetEnumerator() | ForEach-Object {
	$grpGuid = $usedGroupGuids.Get_Item($_.Value.ToUpper());
	if($grpGuid)
	{
		$groupsBuilder.AppendLine(('Project("{{2150E333-8FDC-42A3-9474-1A3956D46DE8}}") = "{0}", "{0}", "{1}"' -f $_.Key, $_.Value.ToUpper())) | Out-Null;
		$groupsBuilder.AppendLine('EndProject') | Out-Null;		
	}
};

Set-Content -Path $slnPfad -Value ( $slnContent -f ( $prjBuilder.ToString(), $cfgBuilder.ToString(), [System.Guid]::NewGuid().ToString().ToUpper(), $postDepBuilder.ToString(), $groupsBuilder.ToString(), $nestedBuilder.ToString() ) );
# entfernt alle leerzeielen
(Get-Content -Path $slnPfad) -match '\S' | Set-Content -Path $slnPfad
$slnPfad | Out-Host;
