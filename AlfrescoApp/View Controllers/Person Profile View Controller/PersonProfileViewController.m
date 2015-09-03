/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "PersonProfileViewController.h"
#import "UIColor+Custom.h"
#import "AvatarManager.h"
#import "RootRevealViewController.h"
#import "UniversalDevice.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "ContactDetailView.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "ThumbnailImageView.h"

static CGFloat const kFadeSpeed = 0.3f;

typedef NS_ENUM(NSUInteger, ContactInformationType)
{
    ContactInformationTypeEmail,
    ContactInformationTypeSkype,
    ContactInformationTypeInstantMessage,
    ContactInformationTypePhone,
    ContactInformationTypeMobile
};

@interface ContactInformation : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *contactInformation;
@property (nonatomic, assign) ContactInformationType contactType;
- (instancetype)initWithTitleText:(NSString *)title contactInformation:(NSString *)contactInformation image:(UIImage *)image contactType:(ContactInformationType)contactType;
@end

@implementation ContactInformation
- (instancetype)initWithTitleText:(NSString *)title contactInformation:(NSString *)contactInformation image:(UIImage *)image contactType:(ContactInformationType)contactType
{
    self = [self init];
    if (self)
    {
        self.image = image;
        self.titleText = title;
        self.contactInformation = contactInformation;
        self.contactType = contactType;
    }
    return self;
}
@end

@interface PersonProfileViewController () <MFMailComposeViewControllerDelegate>
// Layout Constraints
@property (nonatomic, weak) NSLayoutConstraint *summaryHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *companyHeightConstraint;
// Views
@property (nonatomic, weak) UIRefreshControl *refreshControl;
// Gestures
@property (nonatomic, weak) UIGestureRecognizer *addressTappedGesture;
// IBOutlets
@property (nonatomic, weak) IBOutlet ThumbnailImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *countryTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryTitleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *summaryValueTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *contactInfomationTitleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyInfomationTitleTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *companyValueTextLabel;
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *underlineViews;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *summaryContainerView;
@property (nonatomic, weak) IBOutlet UIView *contactDetailsListViewContainer;
@property (nonatomic, weak) IBOutlet UIView *companyContainerView;
// Model
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPerson *person;
@property (nonatomic, strong) NSArray *availableContactInformation;
// Services
@property (nonatomic, strong) AlfrescoPersonService *personService;
@end

@implementation PersonProfileViewController

- (instancetype)initWithUsername:(NSString *)username session:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.username = username;
        self.session = session;
        [self createServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
        if (self.navigationController.viewControllers.firstObject == self)
        {
            self.navigationItem.leftBarButtonItem = hamburgerButtom;
        }
    }
    
    [self initialViewSetup];
    
    if (self.person)
    {
        [self updateViewWithPerson:self.person];
    }
    else
    {
        // Display progress
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:progressHUD];
        progressHUD.removeFromSuperViewOnHide = YES;
        
        [progressHUD show:YES];
        [self retrievePersonForUsername:self.username completionBlock:^(AlfrescoPerson *person, NSError *personError) {
            [progressHUD hide:YES];
        }];
    }
}

#pragma mark - Private Methods

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
}

- (void)reloadView:(id)sender
{
    [self retrievePersonForUsername:self.username completionBlock:nil];
}

- (void)retrievePersonForUsername:(NSString *)username completionBlock:(void (^)(AlfrescoPerson *person, NSError *personError))completionBlock
{
    // Hide the content
    [self showScrollView:NO aminated:YES];
    
    // Get the user
    [self.personService retrievePersonWithIdentifier:self.username completionBlock:^(AlfrescoPerson *person, NSError *error) {
        if (error)
        {
            NSString *errorTitle = NSLocalizedString(@"error.person.profile.no.profile.title", @"Profile Error Title");
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.person.profile.no.profile.message", @"Profile Error Message"), self.username];
            displayErrorMessageWithTitle(errorMessage, errorTitle);
        }
        else
        {
            self.person = person;
            [self updateViewWithPerson:person];
            [self showScrollView:YES aminated:YES];
            [self.refreshControl endRefreshing];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(person, error);
        }
    }];
}

- (void)initialViewSetup
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadView:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.scrollView addSubview:refreshControl];
    
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    self.summaryTitleTextLabel.text = NSLocalizedString(@"person.profile.view.controller.header.title.about", @"About").uppercaseString;
    self.summaryTitleTextLabel.textColor = [UIColor appTintColor];
    self.contactInfomationTitleTextLabel.text = NSLocalizedString(@"person.profile.view.controller.header.title.contact.information", @"Contact Info").uppercaseString;
    self.contactInfomationTitleTextLabel.textColor = [UIColor appTintColor];
    self.companyInfomationTitleTextLabel.text = NSLocalizedString(@"person.profile.view.controller.header.title.company.information", @"Company Information").uppercaseString;
    self.companyInfomationTitleTextLabel.textColor = [UIColor appTintColor];
    
    for (UIView *underlineView in self.underlineViews)
    {
        underlineView.backgroundColor = [UIColor appTintColor];
    }
    
    [self showScrollView:NO aminated:NO];
    
    [self.view layoutIfNeeded];
}

- (void)updateViewWithPerson:(AlfrescoPerson *)person
{
    // Remove all prior settings
    [self.companyContainerView removeGestureRecognizer:self.addressTappedGesture];
    
    // Update the view of the person
    /// Header View
    self.title = (person.fullName) ?: self.username;
    self.titleTextLabel.text = person.jobTitle;
    self.companyTextLabel.text = person.company.name;
    self.countryTextLabel.text = person.location;
    
    /// Person Details - (About)
    // If there is no summary, hide this view
    if (!person.summary || [person.summary isEqualToString:@""])
    {
        self.summaryHeightConstraint = [NSLayoutConstraint constraintWithItem:self.summaryContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        [self.summaryContainerView addConstraint:self.summaryHeightConstraint];
    }
    else if (self.summaryHeightConstraint)
    {
        [self.summaryContainerView removeConstraint:self.summaryHeightConstraint];
    }
    
    self.summaryValueTextLabel.text = (person.summary) ?: NSLocalizedString(@"person.profile.view.controller.value.summary.no.summary", @"No Summary");

    /// Contact Details
    NSArray *availableContactInformation = [self availableContactInformationFromPerson:person];
    self.availableContactInformation = availableContactInformation;
    [self.contactDetailsListViewContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setupSubviewsInContainer:self.contactDetailsListViewContainer forContactInformation:availableContactInformation];
    
    /// Company Information
    NSMutableString *completeAddress = [[NSMutableString alloc] init];
    
    if (person.company.name)
    {
        [completeAddress appendString:[NSString stringWithFormat:@"%@\n", person.company.name]];
    }
    
    NSString *address = [person.company.fullAddress stringByReplacingOccurrencesOfString:@", " withString:@",\n"];
    if (address)
    {
        [completeAddress appendString:address];
    }
    self.companyValueTextLabel.text = completeAddress;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCompanyAddress:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    self.addressTappedGesture = tap;
    [self.companyContainerView addGestureRecognizer:tap];
    
    // If there is no address, hide this view
    if (!address || [address isEqualToString:@""])
    {
        self.companyHeightConstraint = [NSLayoutConstraint constraintWithItem:self.companyContainerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        [self.companyContainerView addConstraint:self.companyHeightConstraint];
    }
    else if (self.summaryHeightConstraint)
    {
        [self.companyContainerView removeConstraint:self.companyHeightConstraint];
    }
    
    /// Request the avatar
    UIImage *avatar = [[AvatarManager sharedManager] avatarForIdentifier:self.username];
    if (avatar)
    {
        self.avatarImageView.image = avatar;
    }
    else
    {
        UIImage *placeholderImage = [UIImage imageNamed:@"avatar.png"];
        self.avatarImageView.image = placeholderImage;
        [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:self.username session:self.session completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
            if (avatarImage)
            {
                [self.avatarImageView setImage:avatarImage withFade:YES];
            }
        }];
    }
}

- (NSArray *)availableContactInformationFromPerson:(AlfrescoPerson *)person
{
    BOOL canSendEmail = [MFMailComposeViewController canSendMail];
    BOOL canMakeCalls = [self canDeviceMakeVoiceCalls];
    
    NSMutableArray *contactDetails = [NSMutableArray array];
    
    ContactInformation *contactInformation = nil;
    if (person.email && ![person.email isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.email.title", @"Email")
                                                        contactInformation:person.email
                                                                     image:(canSendEmail) ? [[UIImage imageNamed:@"contact-details-email.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypeEmail];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.skypeId && ![person.skypeId isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.title", @"Skype")
                                                        contactInformation:person.skypeId
                                                                     image:[[UIImage imageNamed:@"contact-details-skype.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                               contactType:ContactInformationTypeSkype];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.telephoneNumber && ![person.telephoneNumber isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.telephone.title", @"Telephone")
                                                        contactInformation:person.telephoneNumber
                                                                     image:(canMakeCalls) ? [[UIImage imageNamed:@"contact-details-phone.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypePhone];
        [contactDetails addObject:contactInformation];
    }
    
    if (person.mobileNumber && ![person.mobileNumber isEqualToString:@""])
    {
        contactInformation = [[ContactInformation alloc] initWithTitleText:NSLocalizedString(@"person.profile.view.controller.contact.information.type.mobile.title", @"Mobile")
                                                        contactInformation:person.mobileNumber
                                                                     image:(canMakeCalls) ? [[UIImage imageNamed:@"contact-details-phone.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil
                                                               contactType:ContactInformationTypeMobile];
        [contactDetails addObject:contactInformation];
    }
    
    return contactDetails;
}

- (void)setupSubviewsInContainer:(UIView *)containerView forContactInformation:(NSArray *)contactInformation
{
    for (ContactInformation *contactInfo in contactInformation)
    {
        ContactDetailView *contactInfoView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ContactDetailView class]) owner:self options:nil].lastObject;
        contactInfoView.translatesAutoresizingMaskIntoConstraints = NO;
        contactInfoView.titleLabel.textColor = [UIColor appTintColor];
        contactInfoView.titleLabel.text = contactInfo.titleText;
        contactInfoView.valueLabel.text = contactInfo.contactInformation;
        [contactInfoView.actionButton setImage:contactInfo.image forState:UIControlStateNormal];
        [contactInfoView.actionButton addTarget:self action:@selector(contactInformationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:contactInfoView];
    }
    
    // Constraint setup
    NSArray *subviews = containerView.subviews;
    NSMutableArray *constraints = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < subviews.count; i++)
    {
        UIView *currentSubview = subviews[i];
        
        NSLayoutConstraint *topConstraint = nil;
        if (currentSubview == subviews.firstObject)
        {
            topConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        }
        else
        {
            UIView *previousSubview = subviews[i-1];
            topConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previousSubview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        }
        
        NSLayoutConstraint *bottomConstraint = nil;
        if (currentSubview == subviews.lastObject)
        {
            bottomConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        }
        else
        {
            UIView *nextSubview = subviews[i+1];
            bottomConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:nextSubview attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        }
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:currentSubview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:currentSubview.superview attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
        
        [constraints addObject:topConstraint];
        [constraints addObject:bottomConstraint];
        [constraints addObject:leftConstraint];
        [constraints addObject:rightConstraint];
    }
    
    // Add constraints
    [containerView addConstraints:constraints];
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (void)showScrollView:(BOOL)show aminated:(BOOL)animated
{
    CGFloat transitionAlphaValue = (show) ? 1.0f : 0.0f;
    if (animated)
    {
        [UIView animateWithDuration:kFadeSpeed animations:^{
            self.scrollView.alpha = transitionAlphaValue;
        }];
    }
    else
    {
        self.scrollView.alpha = transitionAlphaValue;
    }
}

- (void)contactInformationButtonPressed:(UIButton *)button
{
    NSArray *contactViews = self.contactDetailsListViewContainer.subviews;
    UIView *buttonSuperview = button.superview;
    NSInteger index = [contactViews indexOfObject:buttonSuperview];

    ContactInformation *selectedContactInformation = self.availableContactInformation[index];
    
    switch (selectedContactInformation.contactType)
    {
        case ContactInformationTypeEmail:
        {
            MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
            mailViewController.mailComposeDelegate = self;
            mailViewController.view.tintColor = [UIColor appTintColor];
            
            [mailViewController setToRecipients:@[selectedContactInformation.contactInformation]];
            
            // Content body template
            NSString *footer = [NSString stringWithFormat:NSLocalizedString(@"mail.footer", @"Sent from..."), @"<a href=\"http://itunes.apple.com/app/alfresco/id459242610?mt=8\">Alfresco Mobile</a>"];
            NSString *messageBody = [NSString stringWithFormat:@"<br><br>%@", footer];
            [mailViewController setMessageBody:messageBody isHTML:YES];
            mailViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [self presentViewController:mailViewController animated:YES completion:nil];
        }
        break;
            
        case ContactInformationTypeSkype:
        {
            BOOL skypeInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kSkypeURLScheme]];
            
            if (skypeInstalled)
            {
                void (^handleSkypeRequestWithSkypeCommunicationType)(NSString *) = ^(NSString *contactType) {
                    NSString *skypeString = [NSString stringWithFormat:@"%@%@?%@", kSkypeURLScheme, selectedContactInformation.contactInformation, contactType];
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:skypeString]];
                };
                
                // Actions
                UIAlertAction *chatAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.chat", @"Chat") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    handleSkypeRequestWithSkypeCommunicationType(kSkypeURLCommunicationTypeChat);
                }];
                UIAlertAction *callAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.call", @"Call") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    handleSkypeRequestWithSkypeCommunicationType(kSkypeURLCommunicationTypeCall);
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil];
                
                // Display options
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.title", @"Skype")
                                                                                         message:[NSString stringWithFormat:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.message", @"Message"), selectedContactInformation.contactInformation]
                                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
                [alertController addAction:chatAction];
                [alertController addAction:callAction];
                [alertController addAction:cancelAction];
                
                alertController.popoverPresentationController.sourceView = buttonSuperview;
                alertController.popoverPresentationController.sourceRect = button.frame;
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else
            {
                UIAlertAction *goToAppStoreAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.download", @"Download Skype") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kSkypeAppStoreURL]];
                }];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil];
                
                UIAlertController *goToAppStoreController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.download", @"Download Skype") message:NSLocalizedString(@"person.profile.view.controller.contact.information.type.skype.install.required.message", @"Skype Required") preferredStyle:UIAlertControllerStyleAlert];
                
                [goToAppStoreController addAction:goToAppStoreAction];
                [goToAppStoreController addAction:cancelAction];
                
                [self presentViewController:goToAppStoreController animated:YES completion:nil];
            }
        }
        break;
            
        case ContactInformationTypePhone:
        {
            NSString *phoneNumber = [kPhoneURLScheme stringByAppendingString:selectedContactInformation.contactInformation];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
        }
        break;
            
        case ContactInformationTypeMobile:
        {
            NSString *mobileNumber = [kPhoneURLScheme stringByAppendingString:selectedContactInformation.contactInformation];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mobileNumber]];
        }
        break;
            
        default:
            break;
    }
}

- (BOOL)canDeviceMakeVoiceCalls
{
    BOOL canMakeCalls = NO;
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kPhoneURLScheme]])
    {
        CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *carrier = networkInfo.subscriberCellularProvider;
        NSString *mobileNetworkCode = carrier.mobileNetworkCode;
        if (mobileNetworkCode.length != 0)
        {
            canMakeCalls = YES;
        }
    }
    
    return canMakeCalls;
}

- (void)didTapCompanyAddress:(UIGestureRecognizer *)gesture
{
    NSString *address = [self.person.company.fullAddress stringByReplacingOccurrencesOfString:@" " withString:@"+"];;
    
    NSString *query = [NSString stringWithFormat:@"%@?%@=%@", kMapsURLScheme, kMapsURLSchemeQueryParameter, address];
    NSURL *mapsQueryURL = [NSURL URLWithString:query];
    
    [[UIApplication sharedApplication] openURL:mapsQueryURL];
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultSent:
        case MFMailComposeResultCancelled:
        {
            [controller dismissViewControllerAnimated:YES completion:nil];
        }
        break;
          
        case MFMailComposeResultFailed:
        {
            [controller dismissViewControllerAnimated:YES completion:^{
                displayErrorMessageWithTitle(NSLocalizedString(@"error.person.profile.email.failed.message", @"Email Failed Message"), NSLocalizedString(@"error.person.profile.email.failed.title", @"Sending Failed Title"));
            }];
        }
        break;
            
        default:
            break;
    }
}

@end