//
//  alertmessage.m
//  personalplan
//
//  Created by hidden brains on 17/06/10.
//  Copyright 2010 hiddenbrains. All rights reserved.
//

#import "alertmessage.h"
UIAlertView *av;
UIActivityIndicatorView *actInd;
UIProgressView *progress;

@implementation alertmessage


+(void)ShowAlert{
	if(av!=nil && [av retainCount]>0){ [av release]; av=nil; }
	if(actInd!=nil && [actInd retainCount]>0){ [actInd removeFromSuperview];[actInd release]; actInd=nil; }	
	av=[[UIAlertView alloc] initWithTitle:@"Please wait..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	actInd=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[actInd setFrame:CGRectMake(120, 50, 37, 37)];
	[actInd startAnimating];
	[av addSubview:actInd];
	[av show];
}
+(void)ShowAlertWithTitle:(NSString*)LoadingTitle{
    if(av!=nil && [av retainCount]>0){ [av release]; av=nil; }
	if(actInd!=nil && [actInd retainCount]>0){ [actInd removeFromSuperview];[actInd release]; actInd=nil; }	
	av=[[UIAlertView alloc] initWithTitle:LoadingTitle message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	actInd=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    progress=[[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
    progress.frame=CGRectMake(15, 105, 250, 10);
    progress.progress=0.0;
	[actInd setFrame:CGRectMake(120, 65, 37, 37)];
	[actInd startAnimating];
    [av addSubview:progress];
	[av addSubview:actInd];
	[av show];
}
+(void)updateProcess:(float)progressValue{
    if(progress!=nil && [progress retainCount]>0){
        progress.progress=progressValue;
    }
    
}
+(void)hideAlert{
	[av dismissWithClickedButtonIndex:0 animated:YES];
	if(av!=nil && [av retainCount]>0){ [av release]; av=nil; }
	if(actInd!=nil && [actInd retainCount]>0){ [actInd removeFromSuperview];[actInd release]; actInd=nil; }	
    if(progress!=nil && [progress retainCount]>0){ [progress removeFromSuperview];[progress release]; progress=nil; }	
}

+(void)ShowMessageBoxWithTitle:(NSString*)strTitle Message:(NSString*)strMessage Button:(NSString*)strButtonTitle{
	if(av!=nil && [av retainCount]>0){ [av release]; av=nil; }	
	av = [[UIAlertView alloc]initWithTitle:strTitle message:strMessage  delegate:nil cancelButtonTitle:strButtonTitle otherButtonTitles:nil];
	[av show];
}



- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [super dealloc];
}


@end
