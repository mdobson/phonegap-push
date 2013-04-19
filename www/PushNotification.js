(function(cordova) {
    var cordovaRef = window.PhoneGap || window.Cordova || window.cordova;

	function PushNotification() {}

	// Call this to register for push notifications. Content of [options] depends on whether we are working with APNS (iOS) or GCM (Android)
	PushNotification.prototype.register = function(successCallback, errorCallback, options) {
		cordovaRef.exec(successCallback, errorCallback, "PushPlugin", "register", [options]);
	};

    // Call this to unregister for push notifications
    PushNotification.prototype.unregister = function(successCallback, errorCallback) {
        cordovaRef.exec(successCallback, errorCallback, "PushPlugin", "unregister", []);
    };
 
 
    // Call this to set the application icon badge
    PushNotification.prototype.setApplicationIconBadgeNumber = function(successCallback, badge) {
        cordovaRef.exec(successCallback, successCallback, "PushPlugin", "setApplicationIconBadgeNumber", [{badge: badge}]);
    };
 
    PushNotification.prototype.registerTokenWithPushProvier = function(successCallback, options) {
        if(options.provider === "apigee") {
            this.appName = options["appName"];
            this.orgName = options["orgName"];
            if(options["baseUrl"]) {
                this.baseUrl = options["baseUrl"];
            }
        }
        cordovaRef.exec(successCallback, successCallback, "PushPlugin", "registerWithPushProvider",[options]);
    };
 
    PushNotification.prototype.pushMessage = function(successCallback) {
        var options = {"appName":this.appName, "orgName":this.orgName};
        if(this.baseUrl) {
            options["baseUrl"] = this.baseUrl;
        }
        cordovaRef.exec(successCallback, successCallback, "PushPlugin", "pushNotificationToSelf",[options]);
    };

 cordova.addConstructor(function() {
		if(!window.plugins)
            window.plugins = {};
		window.plugins.pushNotification = new PushNotification();
	});

 })(window.cordova || window.Cordova || window.PhoneGap);
