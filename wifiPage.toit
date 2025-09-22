import log
import .color show *

class wifiPage:
  _ui/any?:=null
  _page/any?:=null
  ssid := ""
  password := ""
  ssidTextArea := {:}
  passwordTextArea := {:}
  saveCredentialsButton := {:}
  currentField:=""
  homeButton := {:}
  xPadding := 10
  yPadding := 30

  constructor --ui/any  --page/any:
    _ui = ui
    _page = page
    // Register this page instance with PageManager
    _page.registerPage "wifiConfigurationPage" this

    ssidTextArea = { "type": "textArea", "x": 10, "y": 25, "width": 460, "height": 50,"text": "ssid", "bgColor": WHITE, "callback": :: |text| switchToSsidInput}
    passwordTextArea = {"type": "textArea", "x": 10, "y": 100, "width": 460, "height": 50, "text": "passwordTextArea", "bgColor": WHITE, "callback": :: |text| switchToPasswordInput }
    saveCredentialsButton = {"type": "button", "x": 120, "y": 175, "width": 250, "height": 50, "text": "Save Credentials", "textColor": WHITE, "bgColor": GRAY, "callback": :: |text| handleSaveCredentials}
    homeButton = { "type": "button", "x": 200, "y": 250, "width": 80, "height": 50, "text": "Home", "textColor": WHITE, "bgColor": GRAY, "callback": :: |text| handleHome}

  handleSave savedText/string:
    if currentField == "ssidInput":
      ssid = savedText
      log.info "SSID updated: $ssid"
    else if currentField == "passwordInput":
      password = savedText
      log.info "Password updated: $password"

  showKeypadForWifi:
    _page.navigateToPage "keypadPage" (:: |text| handleSave text)
    
    
  handleSaveCredentials:
    log.info "WiFi credentials saved successfully"
    ssid=""
    password=""
    //yet to implement the  ssid and password to Save in NVS
    // Save the credentials and maybe navigate back
    _page.navigateToPage "menuPage"

  switchToSsidInput:
    currentField = "ssidInput"
    showKeypadForWifi
  
  switchToPasswordInput:
    currentField = "passwordInput"
    showKeypadForWifi

  // Navigation handlers using PageManager
  handleHome:
    _page.navigateToPage "homePage"

  drawWifiCredentials:
    _ui.clearDisplay
    _ui.uiElements.clear
    _ui.drawElements ssidTextArea
    _ui.drawText ssidTextArea["x"] + xPadding ssidTextArea["y"] + yPadding (ssid.size > 0 ? ssid : "Enter the Ssid") BLACK
    _ui.drawElements passwordTextArea
    _ui.drawText passwordTextArea["x"] + xPadding passwordTextArea["y"] +  yPadding (password.size > 0 ? password : "Enter the Password") BLACK
    _ui.drawElements saveCredentialsButton
    _ui.drawElements homeButton

  showWifiCredentialsPage:
    drawWifiCredentials
    log.info "WiFi Credentials page displayed"