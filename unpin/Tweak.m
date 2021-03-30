#import <Foundation/Foundation.h>
#import <Security/SecureTransport.h>
#import <Security/Security.h>
#import <Security/SecTrust.h>
#import "substrate.h"
#import <dlfcn.h>

/*static OSStatus (*original_SecTrustEvaluate)(SecTrustRef trust, SecTrustResultType *result);
static OSStatus replaced_SecTrustEvaluate(SecTrustRef trust, SecTrustResultType *result) {
    NSLog(@"Entering replaced_SecTrustEvaluate()");
    original_SecTrustEvaluate(trust, result);
    // Actually, this certificate chain is trusted
    *result = 1; //kSecTrustResultUnspecified;
    return 0;
};

static int (*original_SecTrustEvaluateWithError)(void* a, int* error);
static int replaced_SecTrustEvaluateWithError(void* a, int* error) {
   NSLog(@"Entering replaced_SecTrustEvaluateWithError()");
   *error=0;
   return 1;
};

static OSStatus (*original_SecTrustSetPolicies)(void* a, void* policies);
static OSStatus replaced_SecTrustSetPolicies(void* a, void* policies){
  NSLog(@"Entering replaced_SecTrustSetPolicies()");
  return 0;
}
*/

#define SSL_VERIFY_NONE 0
// Constant defined in BoringSSL
enum ssl_verify_result_t {
    ssl_verify_ok = 0,
    ssl_verify_invalid,
    ssl_verify_retry,
};
static int custom_verify_callback_that_does_not_validate(void *ssl, uint8_t *out_alert)
{
    // Yes this certificate is 100% valid...
    return ssl_verify_ok;
}
static void (*original_SSL_set_custom_verify)(void *ssl, int mode, int (*callback)(void *ssl, uint8_t *out_alert));
static void replaced_SSL_set_custom_verify(void *ssl, int mode, int (*callback)(void *ssl, uint8_t *out_alert))
{
    NSLog(@"Entering replaced_SSL_set_custom_verify()");
    original_SSL_set_custom_verify(ssl, SSL_VERIFY_NONE, custom_verify_callback_that_does_not_validate);
    return;
}

/*static int replaced_boringssl_context_set_verify_mode(void *a, void* b) {
    NSLog(@"Entering replaced_boringssl_context_set_verify_mode()");
    return 0;
}*/
char *replaced_SSL_get_psk_identity(void *ssl) {
    NSLog(@"Entering replaced_SSL_get_psk_identity()");
    return "notarealPSKidentity";
}

__attribute__((constructor))
static void init(int argc, const char **argv){
NSLog(@"unpin started");

/*MSHookFunction((void *) SecTrustEvaluate,(void *)  replaced_SecTrustEvaluate, (void **) &original_SecTrustEvaluate);
NSLog(@"SecTrustEvaluate() hooked");
MSHookFunction((void *) SecTrustEvaluateWithError,(void *)  replaced_SecTrustEvaluateWithError, (void **) &original_SecTrustEvaluateWithError);
NSLog(@"SecTrustEvaluateWithError() hooked");
MSHookFunction((void *) SecTrustSetPolicies,(void *)  replaced_SecTrustSetPolicies, (void **) &original_SecTrustSetPolicies);
NSLog(@"SecTrustEvaluateSetPolicies() hooked");
*/

void* boringssl_handle = dlopen("/usr/lib/libboringssl.dylib", RTLD_NOW);
void *SSL_set_custom_verify = dlsym(boringssl_handle, "SSL_set_custom_verify");
if (SSL_set_custom_verify){
    MSHookFunction((void *) SSL_set_custom_verify, (void *) replaced_SSL_set_custom_verify,  (void **) &original_SSL_set_custom_verify);
    NSLog(@"SSL_set_custom_verify() hooked.");
}
void *SSL_get_psk_identity = dlsym(boringssl_handle, "SSL_get_psk_identity");
if (SSL_get_psk_identity) {
     MSHookFunction((void *) SSL_get_psk_identity, (void *) replaced_SSL_get_psk_identity,  (void **) NULL);
     NSLog(@"SSL_get_psk_identity() hooked.");
 }
/*void *boringssl_context_set_verify_mode = dlsym(boringssl_handle, "boringssl_context_set_verify_mode");
if (boringssl_context_set_verify_mode) {
  MSHookFunction((void *) boringssl_context_set_verify_mode, (void *) replaced_boringssl_context_set_verify_mode,  (void **) NULL);
  NSLog(@"boringssl_context_set_verify_mode() hooked.");
}*/

}

/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
