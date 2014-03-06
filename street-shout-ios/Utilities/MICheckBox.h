//
//  MICheckBox.h
//  street-shout-ios
//
//  Created by Baptiste Truchot on 2/28/14.
//  Copyright (c) 2014 Street Shout. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MICheckBox : UIButton

@property (nonatomic,assign) BOOL isChecked;
-(IBAction) checkBoxClicked;

@end
