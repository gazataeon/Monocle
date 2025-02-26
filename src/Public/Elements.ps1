function Set-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Value,

        [switch]
        $Mask,

        [switch]
        $NoClear
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    if ($Mask) {
        Write-MonocleHost -Message "Setting $($id) element value to: ********"
    }
    else {
        Write-MonocleHost -Message "Setting $($id) element value to: $Value"
    }

    # set the value of the element
    if ($Element.TagName -ieq 'select') {
        $select = [OpenQA.Selenium.Support.UI.SelectElement]::new($Element)
        try {
            $select.SelectByText($Value)
        }
        catch {
            $select.SelectByValue($Value)
        }
    }
    else {
        if (!$NoClear) {
            $Element.Clear()
        }

        $Element.SendKeys($Value)
    }
}

function Clear-MonocleElementValue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Clearing $($id) element value"

    # clear the value of the element
    $Element.Clear()
}

function Get-MonocleElementAttribute
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return $Element.GetAttribute($Name)
}

function Test-MonocleElementAttribute
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Value
    )

    try {
        return ((Get-MonocleElementAttribute -Element $Element -Name $Name) -ieq $Value)
    }
    catch {
        return $false
    }
}

function Set-MonocleElementAttribute
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Value
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].setAttribute(arguments[1], arguments[2])' -Arguments $Element, $Name, $Value | Out-Null
}

function Add-MonocleElementClass
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].classList.add(arguments[1])' -Arguments $Element, $Name | Out-Null
}

function Remove-MonocleElementClass
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].classList.remove(arguments[1])' -Arguments $Element, $Name | Out-Null
}

function Test-MonocleElementClass
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Invoke-MonocleJavaScript -Script 'return arguments[0].classList.contains(arguments[1])' -Arguments $Element, $Name)
}

function Submit-MonocleForm
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $WaitUrl
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Submitting form block: $($id)"

    $url = Get-MonocleUrl
    $Element.Submit() | Out-Null
    Start-MonocleSleepWhileBusy

    # check if we should wait until the url is different
    if ($WaitUrl) {
        Wait-MonocleUrlDifferent -FromUrl $url
    }
}

function Get-MonocleElementValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $Mask
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    # get the value of the element
    $value = $Element.Text
    if ($Element.TagName -ieq 'select') {
        $value = [OpenQA.Selenium.Support.UI.SelectElement]::new($Element).SelectedOption.Text
    }

    if ($Mask) {
        Write-MonocleHost -Message "Value of $($id) element: ********"
    }
    else {
        Write-MonocleHost -Message "Value of $($id) element: $value"
    }

    return $value
}

function Test-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath,

        [Parameter(ParameterSetName='Selector')]
        [string]
        $Selector,

        [Parameter(ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Scope = $null
    )

    $result = $null

    try {
        $result = Get-MonocleElementInternal `
            -FilterType $PSCmdlet.ParameterSetName `
            -Id $Id `
            -TagName $TagName `
            -AttributeName $AttributeName `
            -AttributeValue $AttributeValue `
            -ElementValue $ElementValue `
            -XPath $XPath `
            -Selector $Selector `
            -Scope $Scope
    }
    catch { }

    return (($null -ne $result) -and ($null -ne $result.Element))
}

function Wait-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath,

        [Parameter(ParameterSetName='Selector')]
        [string]
        $Selector,

        [Parameter(ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Scope = $null,

        [Parameter()]
        [int]
        $Timeout = 600,

        [switch]
        $WaitVisible,

        [switch]
        $All
    )

    $result = Get-MonocleElementInternal `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath `
        -Selector $Selector `
        -Scope $Scope `
        -Timeout $Timeout `
        -All:$All

    # set the meta id on the element
    @($result.Element) | ForEach-Object {
        Set-MonocleElementId -Element $_ -Id $result.Id
    }

    # wait for the elements to be visible
    if ($WaitVisible) {
        @($result.Element) | ForEach-Object {
            $_ | Wait-MonocleElementVisible | Out-Null
        }
    }

    # return the element
    return $result.Element
}

function Get-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([OpenQA.Selenium.IWebElement[]])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath,

        [Parameter(ParameterSetName='Selector')]
        [string]
        $Selector,

        [Parameter(ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Scope = $null,

        [switch]
        $WaitVisible,

        [switch]
        $All
    )

    # attempt to get the monocle element
    $result = Get-MonocleElementInternal `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath `
        -Selector $Selector `
        -Scope $Scope `
        -All:$All

    # set the meta id on the element
    @($result.Element) | ForEach-Object {
        Set-MonocleElementId -Element $_ -Id $result.Id
    }

    # wait for the elements to be visible
    if ($WaitVisible) {
        @($result.Element) | ForEach-Object {
            $_ | Wait-MonocleElementVisible | Out-Null
        }
    }

    # return the element
    return $result.Element
}

function Wait-MonocleElementVisible
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter()]
        [int]
        $Timeout = 30
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Waiting for element to be visible: $($id)"

    # wait for the element to be visible
    $seconds = 0

    while ($seconds -le $Timeout) {
        if (($Element | Test-MonocleElementVisible)) {
            return $Element
        }

        $seconds++
        Start-Sleep -Seconds 1
    }

    throw "Element '$($id)' was not visible after $($Timeout) seconds"
}

function Measure-MonocleElement
{
    [CmdletBinding(DefaultParameterSetName='Id')]
    [OutputType([int])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Id')]
        [string]
        $Id,

        [Parameter(Mandatory=$true, ParameterSetName='Tag')]
        [string]
        $TagName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeName,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $AttributeValue,

        [Parameter(ParameterSetName='Tag')]
        [string]
        $ElementValue,

        [Parameter(ParameterSetName='XPath')]
        [string]
        $XPath,

        [Parameter(ParameterSetName='Selector')]
        [string]
        $Selector,

        [Parameter(ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Scope = $null
    )

    # attempt to get the monocle element
    $result = Get-MonocleElementInternal `
        -FilterType $PSCmdlet.ParameterSetName `
        -Id $Id `
        -TagName $TagName `
        -AttributeName $AttributeName `
        -AttributeValue $AttributeValue `
        -ElementValue $ElementValue `
        -XPath $XPath `
        -Selector $Selector `
        -Scope $Scope `
        -NoThrow `
        -All

    if ($null -eq $result.Element) {
        return 0
    }

    return @($result.Element).Length
}

function Wait-MonocleValue
{
    [CmdletBinding(DefaultParameterSetName='Value')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Value')]
        [string]
        $Value,

        [Parameter(Mandatory=$true, ParameterSetName='Pattern')]
        [string]
        $Pattern
    )

    $count = 0
    $timeout = Get-MonocleTimeout

    switch ($PSCmdlet.ParameterSetName.ToLowerInvariant())
    {
        'pattern' {
            Write-MonocleHost -Message "Waiting for value to match pattern: $Pattern"

            while ($Browser.PageSource -inotmatch $Pattern) {
                if ($count -ge $timeout) {
                    throw "Expected value to match pattern: $($Pattern)`nBut found nothing`nOn: $(Get-MonocleUrl)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }

        'value' {
            Write-MonocleHost -Message "Waiting for value: $Value"

            while ($Browser.PageSource -ine $Value) {
                if ($count -ge $timeout) {
                    throw "Expected value: $($Value)`nBut found nothing`nOn: $(Get-MonocleUrl)"
                }

                $count++
                Start-Sleep -Seconds 1
            }
        }
    }

    Write-MonocleHost -Message "Expected value loaded after $count second(s)"
    Start-MonocleSleepWhileBusy
}

function Invoke-MonocleElementClick
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $WaitUrl
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element
    Write-MonocleHost -Message "Clicking element: $($id)"

    $url = Get-MonocleUrl

    # attempt to click the element, if it fails for "another element would receive" then try clikcing use javascript
    try {
        $Element.Click() | Out-Null
    }
    catch {
        if ($_.Exception.Message -ilike '*other element would receive the click*') {
            Invoke-MonocleJavaScript -Script 'arguments[0].click()' -Arguments $Element | Out-Null
        }
    }

    Start-MonocleSleepWhileBusy

    # check if we should wait until the url is different
    if ($WaitUrl) {
        Wait-MonocleUrlDifferent -FromUrl $url
    }
}

function Invoke-MonocleElementCheck
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [switch]
        $Uncheck
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    if ($Uncheck) {
        Write-MonocleHost -Message "Unchecking element: $($id)"
        if ($Element.Selected) {
            $Element.Click() | Out-Null
        }
    }
    else {
        Write-MonocleHost -Message "Checking element: $($id)"
        if (!$Element.Selected) {
            $Element.Click() | Out-Null
        }
    }

    Start-MonocleSleepWhileBusy
}

function Test-MonocleElementChecked
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    return $Element.Selected
}

function Test-MonocleElementVisible
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    # run js to check element visibility
    $js = @"
        var doc = document.documentElement
        var isInViewport = true
        var element = arguments[0]

        while (element.parentNode && element.parentNode.getBoundingClientRect) {
            var elemDimension = element.getBoundingClientRect()
            var elemComputedStyle = window.getComputedStyle(element)
            var viewportDimension = {
                width: doc.clientWidth,
                height: doc.clientHeight
            }

            isInViewport = isInViewport &&
                            (elemComputedStyle.display !== 'none' &&
                            elemComputedStyle.visibility === 'visible' &&
                            parseFloat(elemComputedStyle.opacity, 10) > 0 &&
                            elemDimension.bottom > 0 &&
                            elemDimension.right > 0 &&
                            elemDimension.top < viewportDimension.height &&
                            elemDimension.left < viewportDimension.width)

            element = element.parentNode
        }

        return isInViewport
"@

        return (Invoke-MonocleJavaScript -Script $js -Arguments $Element)
}

function Set-MonocleElementCSS
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Value
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].style[arguments[1]] = arguments[2]' -Arguments $Element, $Name, $Value | Out-Null
}

function Remove-MonocleElementCSS
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    Invoke-MonocleJavaScript -Script 'arguments[0].style[arguments[1]] = ""' -Arguments $Element, $Name | Out-Null
}

function Get-MonocleElementCSS
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Invoke-MonocleJavaScript -Script 'return arguments[0].style[arguments[1]]' -Arguments $Element, $Name)
}

function Test-MonocleElementCSS
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Value
    )

    return (Invoke-MonocleJavaScript -Script 'arguments[0].style[arguments[1]] == arguments[2]' -Arguments $Element, $Name, $Value)
}

function Enter-MonocleFrame
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [scriptblock]
        $ScriptBlock
    )

    # get the meta id of the element
    $id = Get-MonocleElementId -Element $Element

    try {
        # enter the iframe
        Write-MonocleHost -Message "Entering iFrame: $($id)"
        $Browser.SwitchTo().Frame($Element) | Out-Null

        # update the depth of output
        Add-MonocleOutputDepth

        # run the scriptblock
        . $ScriptBlock
    }
    finally {
        # reset the depth
        Remove-MonocleOutputDepth

        # exit the iframe back to the default frame
        Write-MonocleHost -Message "Exiting iFrame: $($id)"
        $Browser.SwitchTo().ParentFrame() | Out-Null
    }
}

function Get-MonocleElementSibling
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Previous', 'Next')]
        [string]
        $Type,

        [Parameter()]
        [int]
        $Depth = 1
    )

    if ($Depth -le 0) {
        throw "Sibling depth must be >=1"
    }

    ((1..$Depth) | ForEach-Object {
        $Element = (Invoke-MonocleJavaScript -Script "return arguments[0].$($Type.ToLowerInvariant())ElementSibling" -Arguments $Element)
    })

    return $Element
}

function Get-MonocleElementParent
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter()]
        [int]
        $Depth = 1
    )

    if ($Depth -le 0) {
        throw "Parent depth must be >=1"
    }

    ((1..$Depth) | ForEach-Object {
        $Element = (Invoke-MonocleJavaScript -Script "return arguments[0].parentElement" -Arguments $Element)
    })

    return $Element
}

function Test-MonocleElementChild
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    return (Invoke-MonocleJavaScript -Script "return arguments[0].hasChildNodes()" -Arguments $Element)
}

function Measure-MonocleElementChild
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element
    )

    return (Invoke-MonocleJavaScript -Script "return arguments[0].childElementCount" -Arguments $Element)
}

function Get-MonocleElementChild
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [OpenQA.Selenium.IWebElement]
        $Element,

        [Parameter(Mandatory=$true)]
        [ValidateSet('First', 'Last')]
        [string]
        $Type,

        [Parameter()]
        [int]
        $Depth = 1
    )

    if ($Depth -le 0) {
        throw "Child depth must be >=1"
    }

    ((1..$Depth) | ForEach-Object {
        $Element = (Invoke-MonocleJavaScript -Script "return arguments[0].$($Type.ToLowerInvariant())ElementChild" -Arguments $Element)
    })

    return $Element
}