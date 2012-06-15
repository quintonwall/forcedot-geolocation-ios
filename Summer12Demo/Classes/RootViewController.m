/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "RootViewController.h"

#import "SFRestAPI.h"
#import "SFRestRequest.h"

@implementation RootViewController

@synthesize dataRows;
@synthesize mapView;

#pragma mark Misc

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    self.dataRows = nil;
    [mapView release];
    locationManager.delegate = nil;
    [locationManager release];
    [super dealloc];
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Summer '12 Geolocation Sample App";
    
       
}

//load our map ahead of rendering
- (void) viewWillAppear:(BOOL)animated
{
    //init location services
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m 
    locationManager.purpose = @"This will be used to map vendors who are close to your current location.";
    [locationManager startUpdatingLocation];
    
    
  
    
    //display our map
    self.mapView = [[[MKMapView alloc] initWithFrame:self.view.frame] autorelease];
    //we also want to handle pin clicks
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView]; 
}

#pragma mark - SFRestAPIDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSArray *records = [jsonResponse objectForKey:@"records"];
    NSLog(@"request:didLoadResponse: #records: %d", records.count);
    self.dataRows = records;
    
    //set to our current location and zoom
    mapView.showsUserLocation = YES;
    MKUserLocation *userLocation = mapView.userLocation;
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance (userLocation.location.coordinate, 500, 500);
    [mapView setRegion:region animated:NO];
    
    for (NSDictionary *element in dataRows) {
        NSLog(@"mapping element: %@", [element objectForKey:@"Name"]);
        CLLocationCoordinate2D annotationCoord;
        
        NSArray *keys = element.allKeys;
        NSLog(@"keys: %@", keys);
        
        NSString *latval = [element objectForKey:@"Warehouse_Location__Latitude__s"];
        NSString *longval = [element objectForKey:@"Warehouse_Location__Longitude__s"];
        
        
        annotationCoord.latitude = [latval doubleValue];
        annotationCoord.longitude = [longval doubleValue];
        
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
       // [annotationPoint  setCanShowCallout:NO];
        annotationPoint.coordinate = annotationCoord;
        annotationPoint.title = [element objectForKey:@"Name"];
        
       // if([element objectForKey:@"StreetName__c"] != [NSNull null])
         //   annotationPoint.subtitle = [element objectForKey:@"StreetName__c"];
        
        [mapView addAnnotation:annotationPoint]; 
    }
    
}



- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    //add your failed error handling here
}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    //add your failed error handling here
}

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    //add your failed error handling here
}



#pragma mark - geolocation delegates 

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
        //check to see if we are running in the simulator. If so, we want to set the long/lat
        //to something specific (otherwise it defaults to Apple HQ

        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              newLocation.coordinate.latitude,
              newLocation.coordinate.longitude);
   
    
        NSString *latitude = [[NSString alloc] initWithFormat:@"%+.6f", newLocation.coordinate.latitude];
        NSString *longitude = [[NSString alloc] initWithFormat:@"%+.6f", newLocation.coordinate.longitude];
    
        //fetch nearby vendor records
        NSString *queryString = [NSString stringWithFormat:@"%@%@%@%@%@", 
                @"SELECT Id, Warehouse_Location__latitude__s,  Warehouse_Location__longitude__s, Street_Address__c, Name FROM Vendor__c WHERE DISTANCE(Warehouse_Location__c, GEOLOCATION(", 
                    latitude,
                    @",", 
                    longitude,
                    @"), 'mi') <= 10"
                ];
    
        SFRestRequest *request = [[SFRestAPI sharedInstance] requestForQuery:queryString];    
    
    
        [[SFRestAPI sharedInstance] send:request delegate:self];
        
    }
}



#pragma mark - handle pin events


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    NSLog(@"annotation selected: ,%@",view.annotation.title);
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"annotation deselected: ,%@",view.annotation.title); 
}

@end
