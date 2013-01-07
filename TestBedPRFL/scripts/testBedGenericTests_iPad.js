//
//  testBedGenericTests_iPad.js
//  ActiveCloak
//
//  Created by Apple User on 2/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
// This secion contains utility functions to support testing process

function assertEquals(expected, received, message) 
{
  if (received != expected) 
  {
    if (! message) 
    	message = "Expected " + expected + " but received " + received;
    throw message;
  }
}

function assertTrue(expression, message) 
{
	if (!expression) 
	{
    	if (!message) 
    		message = "Assertion failed";
    	throw message;
  	}
    else if (message)
    {
        UIALogger.logMessage(message);
    }
}

function assertFalse(expression, message) 
{
  	assertTrue(! expression, message);
}

function assertNotNull(thingie, message) 
{
  	if (thingie == null || thingie.toString() == "[object UIAElementNil]") 
  	{
    	if (message == null) 
    		message = "Expected not null object";
    	throw message;
  	}
}

function logElementArrayInfo(elements, title)
{
    UIALogger.logMessage(title + "array count = " + elements.length.toString());
    for (index = 0; index < elements.length; index++)
    {
        UIALogger.logMessage("\elements[" + index.toString() + "].name = '" + elements[index].name() + "'");
    }
}

function test(title, testFunction, options)
{
	if (options == null)
	{
		options = {logTree: true};
	}
	target = UIATarget.localTarget();
	application = target.frontMostApp();
    g_title = title;
	UIALogger.logStart(title);
	try
	{
		testFunction(target, application);
		UIALogger.logPass(title);
	}
	catch (e)
	{
		UIALogger.logError(e);
		if (options.logTree)
		{
			application.logElementTree();
		}
		UIALogger.logFail(title)
	}
    //catch (ReferenceError refError)
    //{
	//	UIALogger.logError(refError);
	//	UIALogger.logFail(title)
    //}
}

function onUnexpectedAlert(alert)
{
    var title = alert.name();
    UIALogger.logMessage("Alert with title = '" + title + "'");
    return false; // use default handler
}

var g_orientationList = 
[
 {numb: UIA_DEVICE_ORIENTATION_UNKNOWN,             name:"UIA_DEVICE_ORIENTATION_UNKNOWN"},
 {numb: UIA_DEVICE_ORIENTATION_PORTRAIT,            name:"UIA_DEVICE_ORIENTATION_PORTRAIT"},
 {numb: UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN, name:"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN"},
 {numb: UIA_DEVICE_ORIENTATION_LANDSCAPELEFT,       name:"UIA_DEVICE_ORIENTATION_LANDSCAPELEFT"},
 {numb: UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT,      name:"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT"},
 {numb: UIA_DEVICE_ORIENTATION_FACEUP,              name:"UIA_DEVICE_ORIENTATION_FACEUP"},
 {numb: UIA_DEVICE_ORIENTATION_FACEDOWN,            name:"UIA_DEVICE_ORIENTATION_FACEDOWN"}
];

function logOrientationName(title, orientation)
{
    var orientationName = "<not found>";
    
    for (index = 0; index < g_orientationList.length; index++)
    {
        if (g_orientationList[index].numb == orientation)
        {
            orientationName = g_orientationList[index].name;
            break;
        }
    }
    UIALogger.logMessage(title + orientationName);
}

function ensureInterfaceOrientation(target, application, orientation)
{
    logOrientationName("ensure Interface Orientation: ", orientation);
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != orientation)
    {
        var deviceOrientation = orientation;
        target.setDeviceOrientation(deviceOrientation);
        currentOrientation = application.interfaceOrientation();
        while (currentOrientation != orientation)
        {
            logOrientationName("current interfaceOrientation: ", currentOrientation);
            target.delay(1);
            currentOrientation = application.interfaceOrientation();
        }
    }
    logOrientationName("ensured Interface Orientation: ", currentOrientation);
}

function ensureInterfaceOrientationPortrait(target, application)
{
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != UIA_DEVICE_ORIENTATION_PORTRAIT &&
        currentOrientation != UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN)
    {
        if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_PORTRAIT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
        }
        else if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN);
        }
        else
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
        }
    }
    
}

function ensureInterfaceOrientationLandscape(target, application)
{
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != UIA_DEVICE_ORIENTATION_LANDSCAPELEFT &&
        currentOrientation != UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT)
    {
        if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_LANDSCAPELEFT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT);
        }
        else if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
        }
        else
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
        }
    }
    
}

function performScrollDown(scrollView, number)
{
    var count = number;
    while (count > 0)
    {
        scrollView.scrollDown();
        target.delay(1);
        count -= 1;
    }
}

function performScrollUp(scrollView, number)
{
    var count = number;
    while (count > 0)
    {
        scrollView.scrollUp();
        target.delay(1);
        count -= 1;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

var const_ResetLogMenuIndex = 0;
var const_ExitMediaPLayerMenuIndex = 1;
var const_SendStatusReportMenuIndex = 2;
var const_SendListOfTestsMenuIndex = 3;
var const_SwitchToDemoModeMenuIndex = 4;
var const_SwitchToTestModeMenuIndex = 2;

var str_TestModePopupMenuName = "testModePopupMenu";
var str_DemoModePopupMenuName = "demoModePopupMenu";

var g_title = null;
var g_aboutInfoIsValid = false;

////////////////////////////////////////////////////////////////////////////////
// These are utility functions to support TestBed testing

function onAboutInfoAlert(alert)
{
    var staticTexts = alert.staticTexts();
    var title = staticTexts.length > 0 ? staticTexts[0].name() : "<null>";
    UIALogger.logMessage("Alert with title = '" + title + "'");
    alert.logElementTree();
    g_aboutInfoIsValid = staticTexts.length == 2 && staticTexts[0].name() == "TestBed" && 
        staticTexts[1].name().substr(0, 33) == "Copyright (C) 2010, Irdeto Canada";
    //target.delay(3);
    return false; // use default handler
} 

function onPopupMenu(menu)
{
    var title = menu.name();
    UIALogger.logMessage("Alert with title = '" + title + "'");
    return false; // use default handler
} 

function tapActionSheetButton(target, actionSheet, buttonIndex)
{
    var headerHeight = 28;
    var buttonHeight = 50;
    
    if (buttonIndex >= 0) 
    {
        var actionSheetRect = actionSheet.rect();
        UIALogger.logMessage("actionSheet:{rect:{origin:{x:" + actionSheetRect.origin.x.toString() 
                             + ", y:" + actionSheetRect.origin.y.toString()
                             + "}, size:{width:" + actionSheetRect.size.width.toString()
                             + ", height:" + actionSheetRect.size.height.toString()
                             + "}}}");
        var xOffset = actionSheetRect.size.width / 2;
        var yOffset = headerHeight + buttonIndex * buttonHeight + buttonHeight / 2;
        if (yOffset < actionSheetRect.size.height) {
            var tap_x = actionSheetRect.origin.x + xOffset;
            var tap_y = actionSheetRect.origin.y + yOffset;
            target.tap({x:tap_x, y:tap_y});
        }
    }
    else
    {
        var message = "Cannot tap button " + buttonIndex.toString() + ". It does not exist";
        throw message;
    }
}

function checkMenuPopoverDismissed(mainWindow)
{
    var popover = mainWindow.popover();
    while (popover != null 
           && popover.isValid()
           && popover.actionSheet() != null
           && popover.actionSheet().isValid())
    {
        target.delay(1);
        popover = mainWindow.popover();
    }
    
    target.delay(1);
}

function performMenuAction(target, application, menuName, menuItemIndex)
{
    var mainWindow = application.mainWindow();
    var currentOnAlert = UIATarget.onAlert;
    UIATarget.onAlert = onUnexpectedAlert;
    
    var menuButton = mainWindow.toolbars()[0].buttons()["Menu"];
    assertTrue(menuButton != null, "Top toolbar Menu button exists");
    UIALogger.logMessage("Found 'Menu' button");
    
    menuButton.tap();
    
    var popoverMenu = mainWindow.popover();
    var actionSheet = popoverMenu.actionSheet();
    assertTrue(actionSheet != null 
               && actionSheet.name() == menuName /*"testModePopupMenu"*/ 
               && actionSheet.isValid(), 
               "Action Sheet from Menu button has poped up.");
    
    assertTrue(actionSheet.buttons().length <= 0, "Action Sheet does not show any buttons by default");
    tapActionSheetButton(target, actionSheet, menuItemIndex);
    target.delay(1);
    
    checkMenuPopoverDismissed(mainWindow);
    
    UIATarget.onAlert = currentOnAlert;
}

function verifyApplicationInDemoMode(target, application)
{
    var mainWindow = application.mainWindow();
    var demoButtons = mainWindow.buttons();
    // logElementArrayInfo(demoButtons, "Demo window buttons ");
    var demoImages = mainWindow.images();
    var titleScreenImage = demoImages["TitleScreen"];
    return demoButtons.length == 6 && titleScreenImage.isValid() && titleScreenImage.name() == "TitleScreen";
}

function verifyApplicationInTestMode(target, application)
{
    var success = true;
    var mainWindow = application.mainWindow();
    var staticTexts = mainWindow.staticTexts();
    logElementArrayInfo(staticTexts, "Test window static text ");
    var toolbars = mainWindow.toolbars();
    if (toolbars.length == 2 && staticTexts.length == 2) 
    {
        var topToolbar = toolbars[0];
        var bottomToolbar = toolbars[1];
        var topButtons = topToolbar.buttons();
        logElementArrayInfo(topButtons, "Top toolbar buttons ");
        
        var currentOrientation = application.interfaceOrientation();
        var numberOfTopToolbarButtons = 3;
        if (currentOrientation == UIA_DEVICE_ORIENTATION_LANDSCAPELEFT
            || currentOrientation == UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT) {
            UIALogger.logMessage("currentOrientation = " 
                                 + (currentOrientation == UIA_DEVICE_ORIENTATION_LANDSCAPELEFT ? "UIA_DEVICE_ORIENTATION_LANDSCAPELEFT" :
                                   (currentOrientation == UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT ? "UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT" : 
                                 currentOrientation.toString())));
            numberOfTopToolbarButtons = 2;
        }
        
        if (topButtons.length == numberOfTopToolbarButtons)
        {
            var aboutInfoButton = topButtons["aboutInfoButton"];
            var menuButton = topButtons["Menu"];
            var applicationNameLabel = staticTexts["applicationNameLabel"];
            var netServiceLabel = staticTexts["netServiceLabel"];
            success = aboutInfoButton.isValid() && aboutInfoButton.name() == "aboutInfoButton"
            && menuButton.isValid() && menuButton.name() == "Menu"
            && applicationNameLabel.isValid() && applicationNameLabel.name() == "applicationNameLabel"
            && netServiceLabel.isValid() && netServiceLabel.name() == "netServiceLabel";
        }
        else
        {
            success = false;
        }
    }
    else
    {
        success = false;
    }
    
    return success;
}

////////////////////////////////////////////////////////////////////////////////
// This section contains test functions to run

function showAboutInfo (target, application)
{
	assertTrue(target != null, "Verifeid 'target' != null");
    
	assertTrue(application != null, "Verified 'application' != null");
	
    var mainWindow = application.mainWindow();
	assertTrue(mainWindow != null, "Verified 'mainWindow' != null");
    
    UIATarget.onAlert = onUnexpectedAlert;

    var toolbars = mainWindow.toolbars();
    logElementArrayInfo(toolbars, "Main window toolbars ");
    assertTrue(toolbars.length == 2, "Verfied that 2 toolbars exist");
    
    var topToolbar = toolbars[0];
    var bottomToolbar = toolbars[1];
    
    var topButtons = topToolbar.buttons();
    logElementArrayInfo(topButtons, "Top toolbar button ");
    
    var aboutInfoButton = topButtons.firstWithName("aboutInfoButton");
    assertTrue(aboutInfoButton != null, "About Info button exists");
    
    
    // show About information
    UIALogger.logMessage("Show About information");
    UIATarget.onAlert = onAboutInfoAlert;
    aboutInfoButton.tap();
    UIALogger.logMessage("Tapped info button");
        
    // delay script for 3 seconds
    target.delay(1);
    assertTrue(g_aboutInfoIsValid, "About Info dialog appeared correctly");
    
    UIATarget.onAlert = onUnexpectedAlert;
    target.delay(1);
    
}

function navigateAndPlayVideoTestsInPortraitMode(target, application)
{
    var mainWindow = application.mainWindow();
    var currentOnAlert = UIATarget.onAlert;
    UIATarget.onAlert = onUnexpectedAlert;

    // remember the orientation
    var currentOrientation = application.interfaceOrientation();
    
    // change orientation if it is required
    ensureInterfaceOrientationPortrait(target, application);
    
    assertTrue(verifyApplicationInTestMode(target, application), "Application in Test Mode");

    target.captureScreenWithName("beforeTest"); // specify a name for the screenshot
    
    var testsButton = mainWindow.toolbars()[0].buttons()["Tests"];
    assertTrue(testsButton != null, "Top toolbar 'Tests' button exists");
    
    testsButton.tap();
    
    var popover = mainWindow.popover();
    assertTrue(popover.isValid, "Popover menu exists");
    popover.logElementTree();
    
    var solutionTestsCell = popover.tableViews()[0].cells()["SolutionTests"];
    assertTrue(solutionTestsCell != null && solutionTestsCell.name() == "SolutionTests", "SolutionTests group exists");
    
    solutionTestsCell.tap();
    target.delay(2);
    
    var videoTestsCell = popover.tableViews()[0].cells()["VideoTests"];
    assertTrue(videoTestsCell != null && videoTestsCell.name() == "VideoTests", "VideoTests group exists");

    videoTestsCell.tap();
    
    var avatarUrlCell = popover.tableViews()[0].cells()["Avatar Behind-the-Scenes"];
    var bbbUrlCell = popover.tableViews()[0].cells()["Big Buck Bunny"];
    var playCurrentlySelectedVideoCell = popover.tableViews()[0].cells()["Play Currently Selected Video"];

    var bbbSelectButton = bbbUrlCell.elements()["Run"];
    var avatarSelectButton = avatarUrlCell.elements()["Run"];
    var playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    
    target.delay(2);
    bbbSelectButton.tap();
    target.delay(3);
    playVideoButton.tap();
    
    target.delay(15);
    target.captureScreenWithName("playingBbb"); // specify a name for the screenshot
    
    target.delay(2);
    avatarSelectButton.tap();
    target.delay(3);
    playVideoButton.tap();
    
    target.delay(30);
    target.captureScreenWithName("playingAvatar"); // specify a name for the screenshot

    performMenuAction(target, application, str_TestModePopupMenuName, const_ExitMediaPLayerMenuIndex);

    // wait until media player stops working
    target.delay(2);
    
    var navigationBar = popover.navigationBar();
    assertTrue(navigationBar.isValid(), "Obtained navigationBar");
    var navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar contains 2 buttons");
    var solutionTestsButton = navigationBarButtons["SolutionTests"];
    assertTrue(solutionTestsButton.isValid(), "Obtained 'SolutionTests' button in the navigationBar");
    
    solutionTestsButton.tap();
    target.delay(1);
    
    navigationBar = popover.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar still contains 2 buttons");
    var testsButton = navigationBarButtons["Tests"];
    assertTrue(testsButton.isValid(), "Obtained 'Tests' button in the navigationBar");
    
    testsButton.tap();
    target.delay(1);
    
    navigationBar = popover.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 1 && navigationBarButtons[0].name() == "Run", "Navigation has only Run button");
    target.delay(1);

    // restore orientation
    ensureInterfaceOrientation(target, application, currentOrientation);
}

function scrollingTableViewInLandscapeMode(target, application)
{
    var mainWindow = application.mainWindow();
    // remember the orientation
    var currentOrientation = application.interfaceOrientation();
    
    ensureInterfaceOrientationLandscape(target, application);
    
    assertTrue(verifyApplicationInTestMode(target, application), "Application in Test Mode");
    
    target.captureScreenWithName("beforeTest"); // specify a name for the screenshot
    UIATarget.onAlert = onUnexpectedAlert;
    var solutionTestsCell = mainWindow.tableViews()[0].cells()["SolutionTests"];
    assertTrue(solutionTestsCell != null && solutionTestsCell.name() == "SolutionTests", "SolutionTest group exists");
    
    //target.delay(5);
    
    solutionTestsCell.tap();
    
    var videoTestsCell = mainWindow.tableViews()[0].cells()["VideoTests"];
    assertTrue(videoTestsCell != null && videoTestsCell.name() == "VideoTests", "VideoTests group exists");
    
    //target.delay(5);
    
    videoTestsCell.tap();
    target.delay(3);
    
    performScrollDown(mainWindow.tableViews()[0], 2);
    target.delay(3);
    performScrollUp(mainWindow.tableViews()[0], 2);
    target.delay(3);
}

function navigateAndPlayVideoTestsInLandscapeMode(target, application)
{
    var mainWindow = application.mainWindow();
    // remember the orientation
    var currentOrientation = application.interfaceOrientation();
    
    ensureInterfaceOrientationLandscape(target, application);
    
    assertTrue(verifyApplicationInTestMode(target, application), "Application in Test Mode");
    
    target.captureScreenWithName("beforeTest"); // specify a name for the screenshot
    UIATarget.onAlert = onUnexpectedAlert;
    var solutionTestsCell = mainWindow.tableViews()[0].cells()["SolutionTests"];
    assertTrue(solutionTestsCell != null && solutionTestsCell.name() == "SolutionTests", "SolutionTest group exists");
    
    //target.delay(5);
    
    solutionTestsCell.tap();
    
    var videoTestsCell = mainWindow.tableViews()[0].cells()["VideoTests"];
    assertTrue(videoTestsCell != null && videoTestsCell.name() == "VideoTests", "VideoTests group exists");
    
    //target.delay(5);
    
    videoTestsCell.tap();
    
    var avatarUrlCell = mainWindow.tableViews()[0].cells()["Avatar Behind-the-Scenes"];
    assertTrue(avatarUrlCell.isValid(), "Obtained Avatar URL Cell");
    var bbbUrlCell = mainWindow.tableViews()[0].cells()["Big Buck Bunny"];
    assertTrue(bbbUrlCell.isValid(), "Obtained Big Buck Bunny URL Cell");
    //var playCurrentlySelectedVideoCell = mainWindow.tableViews()[0].cells()["Play Currently Selected Video"];
    //assertTrue(playCurrentlySelectedVideoCell.isValid(), "Obtained 'Play Currently Selected Video' Cell"); 
    
    var bbbSelectButton = bbbUrlCell.elements()["Run"];
    assertTrue(bbbSelectButton.isValid(), "Obtained Big Buck Bunny URL 'Run' button")
    var avatarSelectButton = avatarUrlCell.elements()["Run"];
    assertTrue(avatarSelectButton.isValid(), "Obtained Avatar URL 'Run' button")
    //var playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    //assertTrue(playVideoButton.isValid(), "Obtained Play Currently Selected Video 'Run' button")
    
    //target.delay(2);
    bbbSelectButton.tap();
    //target.delay(2);
    //playVideoButton.tap();
    
    target.delay(15);
    target.captureScreenWithName("playingBbb"); // specify a name for the screenshot
    
    //target.delay(2);
    avatarSelectButton.tap();
    //target.delay(2);
    //playVideoButton.tap();
    
    target.delay(30);
    target.captureScreenWithName("playingAvatar"); // specify a name for the screenshot
    
    performScrollDown(mainWindow.tableViews()[0], 1);
    target.delay(1);
    var expendablesUrlCell = mainWindow.tableViews()[0].cells()["The Expendables"];
    assertTrue(expendablesUrlCell.isValid(), "Obtained The Expendables URL Cell");
    var expendablesSelectButton = expendablesUrlCell.elements()["Run"];
    
    expendablesSelectButton.tap();
    
    target.delay(20);
    target.captureScreenWithName("playingExpendables"); // specify a name for the screenshot
    
    performScrollUp(mainWindow.tableViews()[0], 1);
    performMenuAction(target, application, str_TestModePopupMenuName, const_ExitMediaPLayerMenuIndex);

    // wait until media player stops working
    target.delay(2);

    var navigationBar = mainWindow.navigationBar();
    assertTrue(navigationBar.isValid(), "Obtained navigationBar");
    var navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar contains 2 buttons");
    var solutionTestsButton = navigationBarButtons["SolutionTests"];
    assertTrue(solutionTestsButton.isValid(), "Obtained 'SolutionTests' button in the navigationBar");
    
    solutionTestsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar still contains 2 buttons");
    var testsButton = navigationBarButtons["Tests"];
    assertTrue(testsButton.isValid(), "Obtained 'Tests' button in the navigationBar");
    
    testsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 1 && navigationBarButtons[0].name() == "Run", "Navigation has only Run button");
    target.delay(1);
    
    // restore orientation
    ensureInterfaceOrientation(target, application, currentOrientation);
}

function navigateToDemoModeAndBack(target, application)
{
    var mainWindow = application.mainWindow();
    UIATarget.onAlert = onUnexpectedAlert;

    performMenuAction(target, application, str_TestModePopupMenuName, const_SwitchToDemoModeMenuIndex);

    assertTrue(verifyApplicationInDemoMode(target, application), "Application in Demo Mode");
    
    performMenuAction(target, application, str_DemoModePopupMenuName, const_SwitchToTestModeMenuIndex);
    
    assertTrue(verifyApplicationInTestMode(target, application), "Application in Test Mode");
}

function changeOrientation(target, application)
{
    
    var currentOrientation = application.interfaceOrientation();
    
    logOrientationName("currentOrientation = ", currentOrientation);

    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT);
    ensureInterfaceOrientation(target, application, currentOrientation);
}

////////////////////////////////////////////////////////////////////////////////
// This section contains the sequense of tests 

try
{
    //test("Change Orientation", changeOrientation, null);
    
    //test("Show About Info", showAboutInfo, null);
    
    //test("Scrolling Table in Landscape", scrollingTableViewInLandscapeMode, null);
    
    test("Navigate And Play Video Tests in Landscape Mode", navigateAndPlayVideoTestsInLandscapeMode, null);

    //test("Navigate to Demo mode and back", navigateToDemoModeAndBack, null);
    
    //test("Navigate And Play Video Test in Portrait Mode", navigateAndPlayVideoTestsInPortraitMode, null);

} 
catch (e)
{
	UIALogger.logError(e);
	if (options.logTree)
	{
		application.logElementTree();
	}
	UIALogger.logFail(title)
}

