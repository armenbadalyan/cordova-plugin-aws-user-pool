#import "AwsUserPoolPlugin.h"

    @implementation AwsUserPoolPlugin

	AWSRegionType const CognitoIdentityUserPoolRegion = AWSRegionEUWest1;

    - (void)init:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

		self.CognitoIdentityUserPoolId = [options objectForKey:@"CognitoIdentityUserPoolId"];
		self.CognitoIdentityUserPoolAppClientId = [options objectForKey:@"CognitoIdentityUserPoolAppClientId"];
		self.CognitoIdentityUserPoolAppClientSecret = [options objectForKey:@"CognitoIdentityUserPoolAppClientSecret"];
        self.User = nil;

        CDVPluginResult *pluginResult;

        //setup service config
        AWSServiceConfiguration *serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:CognitoIdentityUserPoolRegion credentialsProvider:nil];
        
        //create a pool
        AWSCognitoIdentityUserPoolConfiguration *configuration = [[AWSCognitoIdentityUserPoolConfiguration alloc] initWithClientId:self.CognitoIdentityUserPoolAppClientId  clientSecret:self.CognitoIdentityUserPoolAppClientSecret poolId:self.CognitoIdentityUserPoolId];
        
        [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:serviceConfiguration userPoolConfiguration:configuration forKey:@"UserPool"];
        
        self.Pool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:@"UserPool"];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Initialization successful"];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

    - (void)signIn:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *username = [options objectForKey:@"username"];
        NSString *password = [options objectForKey:@"password"];

        self.User = [self.Pool getUser:username];
    
        [[self.User getSession:username password:password validationData:nil] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserGetDetailsResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else{
                    AWSCognitoIdentityUserGetDetailsResponse *response = task.result;
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Authentification sucess"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)signUp:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];
        NSMutableArray * attributes = [NSMutableArray new];

        NSString *passwordString = [options objectForKey:@"password"];
        NSString *nameString = [options objectForKey:@"name"];
        NSString *idString = [options objectForKey:@"id"];
        NSString *emailString = [options objectForKey:@"email"];

        AWSCognitoIdentityUserAttributeType * email = [AWSCognitoIdentityUserAttributeType new];
        email.name = @"email";
        email.value = emailString;

        
        AWSCognitoIdentityUserAttributeType * name = [AWSCognitoIdentityUserAttributeType new];
        name.name = @"name";
        name.value = nameString;

        if(![@"" isEqualToString:email.value]){
            [attributes addObject:email];
        }
        if(![@"" isEqualToString:name.value]){
            [attributes addObject:name];
        }

        //sign up the user
        [[self.Pool signUp:idString password:passwordString userAttributes:attributes validationData:nil] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserPoolSignUpResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else{
                    AWSCognitoIdentityUserPoolSignUpResponse * response = task.result;
                    if(!response.userConfirmed){
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    }
                    else {
                        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];                       
                    }
                }});
            return nil;
        }];
    }

    - (void)confirmSignUp:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *tokenString = [options objectForKey:@"token"];
        NSString *idString = [options objectForKey:@"id"];

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User confirmSignUp:tokenString forceAliasCreation:YES] continueWithBlock: ^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)forgotPassword:(CDVInvokedUrlCommand*)command{
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];        

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User forgotPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserForgotPasswordResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    - (void)updatePassword:(CDVInvokedUrlCommand*)command {
        //confirm forgot password with input from ui.

        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *confirmationCode = [options objectForKey:@"confirmationCode"];
        NSString *newPassword = [options objectForKey:@"newPassword"];

        [[self.User confirmForgotPassword:confirmationCode password:newPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"error"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"good token"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            return nil;
        }];
    }

    -(void)getDetails:(CDVInvokedUrlCommand*)command {
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];        

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User getDetails] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserGetDetailsResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:task.error.userInfo[@"NSLocalizedDescription"]];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                } else {
                    AWSCognitoIdentityUserGetDetailsResponse *response = task.result;
                    for (AWSCognitoIdentityUserAttributeType *attribute in response.userAttributes) {
                        NSLog(@"Attribute: %@ Value: %@", attribute.name, attribute.value);
                    }
                    // CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:task.result.userAttributes];
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ok"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            });
            
            return nil;
        }];
    }

    - (void)resendConfirmationCode:(CDVInvokedUrlCommand*)command {
        NSMutableDictionary* options = [command.arguments objectAtIndex:0];

        NSString *idString = [options objectForKey:@"id"];        

        if (idString) {
            self.User = [self.Pool getUser:idString];
        }

        [[self.User resendConfirmationCode] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserResendConfirmationCodeResponse *> * _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(task.error){

                } else {

                }
            });
            return nil;
        }];
    }
    @end