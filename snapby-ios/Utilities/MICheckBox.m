//
//  MICheckBox.m
//  snapby-ios
//
//  Created by Baptiste Truchot on 2/28/14.
//  Copyright (c) 2014 Snapby. All rights reserved.
//

#import "MICheckBox.h"

@implementation MICheckBox

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
        
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"]
              forState:UIControlStateNormal];
        
        [self addTarget:self action:
         @selector(checkBoxClicked)
       forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(IBAction) checkBoxClicked{
    if(self.isChecked ==NO){
        self.isChecked =YES;
        [self setImage:[UIImage imageNamed:@"checkbox_ticked.png"]
              forState:UIControlStateNormal];
        
    }else{
        self.isChecked =NO;
        [self setImage:[UIImage imageNamed:@"checkbox_not_ticked.png"]
              forState:UIControlStateNormal];
    }
}


@end
