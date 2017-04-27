//
//  MainViewController.m
//  BapEclocking
//
//  Created by BapVn on 4/20/17.
//  Copyright © 2017 blockchain@bap.jp. All rights reserved.
//

#import "MainViewController.h"
#import <EstimoteSDK/EstimoteSDK.h>
#import "BeaconID.h"
@import Firebase;
@interface MainViewController ()<ESTBeaconManagerDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITextView *tvWelcome;
@property (weak, nonatomic) IBOutlet UITextView *txtStatus;
@property (nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic) NSArray * beaconIDs;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (strong, nonatomic) FIRDatabaseReference *refData;
@property (nonatomic) CLBeacon *nearestBeacon;
@property (weak, nonatomic) IBOutlet UITableView *tableTimeSheet;
@property (nonatomic) NSMutableArray *tableData;
@property (nonatomic) NSString *todayStr;
@property (nonatomic) NSString *userName;
@property (nonatomic) BOOL needCheckin;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([FIRAuth auth].currentUser) {
        _userName =  [FIRAuth auth].currentUser.displayName;
        if(!_userName) _userName = [FIRAuth auth].currentUser.email;
    }

    self.tvWelcome.text = [NSString stringWithFormat:@"Welcome %@", _userName];
    
    [self setupBeacon];
    
    self.ref = [[FIRDatabase database] reference];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    _todayStr = [dateFormatter stringFromDate:[NSDate date]];
    self.tableData = [[NSMutableArray alloc] init];
    [self startObservingDatabase];
  
    
    
}
- (void) setupBeacon
{
    self.beaconManager = [ESTBeaconManager new];
    self.beaconManager.delegate = self;
    
    [self.beaconManager requestAlwaysAuthorization];
    _beaconIDs = @[
                  [[BeaconID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D" major:57207 minor:64392],
                  [[BeaconID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D" major:3686 minor:25826],
                  [[BeaconID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D" major:48616 minor:46108]
                  ];
    
    for (BeaconID *beacon in _beaconIDs) {
        [self.beaconManager startMonitoringForRegion:beacon.asBeaconRegion];
        
    }
    
}
- (void) startRangingBeaconsInRegion
{
    for (BeaconID *beacon in _beaconIDs) {
        [self.beaconManager startRangingBeaconsInRegion:beacon.asBeaconRegion];
        
    }
}
- (void) stopRangingBeaconsInRegion
{
    for (BeaconID *beacon in _beaconIDs) {
        [self.beaconManager stopRangingBeaconsInRegion:beacon.asBeaconRegion];
        
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillAppear:(BOOL)animated
{
    [self startRangingBeaconsInRegion];
}
- (void) viewDidDisappear:(BOOL)animated
{
    [self stopRangingBeaconsInRegion];
}
/*
#pragma mark - MonitoringForRegion
*/
- (void)beaconManager:(id)manager didEnterRegion:(CLBeaconRegion *)region
{
    [self showNotificationWithMessage:[NSString stringWithFormat:@"Hello %@", _userName]];
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)])
    {
        UIApplication * application = [UIApplication sharedApplication];
        NSLog(@"Multitasking Supported");

        __block UIBackgroundTaskIdentifier background_task;
        background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
            
            //Clean up code. Tell the system that we are done.
            _needCheckin = NO;
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        }];
        
        //To make the code block asynchronous
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //### background task starts
            NSLog(@"Running in the background\n");
            [self startRangingBeaconsInRegion];
            
            if (![FIRAuth auth].currentUser) {
                [self autoLogin];
            }else
            {
                while(!_needCheckin)
                {
                    NSLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                    [NSThread sleepForTimeInterval:1]; //wait for 1 sec
                }
                if(_needCheckin)
                {
                    [self checkInCheckOut];
                }
            }
            //Clean up code. Tell the system that we are done.
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid; 
        });
    }
    else
    {
        NSLog(@"Multitasking Not Supported");
    }
    
    

}
- (void) checkInCheckOut
{
    if(![FIRAuth auth].currentUser) return;
    NSString * uid = [FIRAuth auth].currentUser.uid;

    
    [[[[[_ref child:@"users"] child:uid] child:_todayStr] childByAutoId]
     setValue:@{@"timesheet": [FIRServerValue timestamp]}];
    _needCheckin = NO;
    [self showNotificationWithMessage:[NSString stringWithFormat:@"Checkin successful!"]];
    
}
- (void)beaconManager:(id)manager  didExitRegion:(CLBeaconRegion *)region
{
    [self showNotificationWithMessage:[NSString stringWithFormat:@"Bye %@", _userName]];
}
/*
 #pragma mark - RangingForRegion
 */

- (void)beaconManager:(id)manager
      didRangeBeacons:(NSArray<CLBeacon *> *)beacons
             inRegion:(CLBeaconRegion *)region
{
    _nearestBeacon = beacons.firstObject;
    
    if (_nearestBeacon) {

        switch (_nearestBeacon.proximity) {
            case CLProximityImmediate:
                _needCheckin = YES;
                NSLog(@"\nImmediate");
                _txtStatus.text = [NSString stringWithFormat:@"Immediate %@", _nearestBeacon.beaconID.asString];
                
                break;
            case CLProximityNear:
                _needCheckin = YES;
                 NSLog(@"\nNear");
                _txtStatus.text = [NSString stringWithFormat:@"Near %@", _nearestBeacon.beaconID.asString];
                break;
            case CLProximityFar:
                 NSLog(@"\nFar");
                 _txtStatus.text =  [NSString stringWithFormat:@"Far %@", _nearestBeacon.beaconID.asString];
                break;
                
            default:
                
                _txtStatus.text = [NSString stringWithFormat:@"Unknow %@", _nearestBeacon.beaconID.asString];
                break;
        }
        NSLog(@"Distance: ~ %f", _nearestBeacon.accuracy);
    }
}

- (void)showNotificationWithMessage:(NSString *)message {
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}
- (void)beaconManager:(id)manager
monitoringDidFailForRegion:(CLBeaconRegion * _Nullable)region
            withError:(NSError *)error
{
}
- (void)beaconManager:(id)manager didFailWithError:(NSError *)error
{
    
}
- (void)beaconManager:(id)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion * _Nullable)region withError:(NSError *)error
{

}
- (void) autoLogin
{
    NSString * email = [[NSUserDefaults standardUserDefaults] stringForKey:@"EMAIL"];
    NSString * pass = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    
    [[FIRAuth auth] signInWithEmail:email
                           password:pass
                         completion:^(FIRUser *user, NSError *error) {
                             if (user && _needCheckin) {
                                 [self checkInCheckOut];
                             }
                         }];
}
- (void) startObservingDatabase
{

        NSString * uid = [FIRAuth auth].currentUser.uid;
    NSString * dataPath = [NSString stringWithFormat:@"users/%@/%@", uid, _todayStr ];
    _refData = [_ref child:dataPath];
        [_refData
         observeEventType:FIRDataEventTypeChildAdded
         withBlock:^(FIRDataSnapshot *snapshot) {
             
             NSDictionary *postDict = snapshot.value;
             NSNumber * timestamp = postDict[@"timesheet"];
              [self.tableData insertObject:timestamp atIndex:0];
             dispatch_async(dispatch_get_main_queue(), ^{
                  [self.tableTimeSheet reloadData];
             });
         }];
        // Listen for deleted comments in the Firebase database
        [_refData
         observeEventType:FIRDataEventTypeChildRemoved
         withBlock:^(FIRDataSnapshot *snapshot) {
              NSDictionary *postDict = snapshot.value;
             int index = [self.tableData indexOfObject:postDict[@"timesheet"]];
             [self.tableData removeObjectAtIndex:index];
              [self.tableTimeSheet reloadData];
             [self.tableTimeSheet deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationAutomatic];
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.tableTimeSheet reloadData];
             });
         }];

}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    NSNumber *timestamp =  self.tableData[indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@" %@",[self timestampToLocalDate:timestamp]];
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:
(NSInteger)section{
    NSString *headerTitle;
    if (section==0) {
        headerTitle = @"History check in today:";
    }
    return headerTitle;
}
- (NSString *) timestampToLocalDate:(NSNumber *) timestamp
{
    
    NSTimeInterval _interval=[timestamp doubleValue]/1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *formatter= [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm a"];
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void) dealloc
{
    [[_ref child:[NSString stringWithFormat:@"users/%@",_todayStr]] removeObserverWithHandle:_refData];
}
@end
