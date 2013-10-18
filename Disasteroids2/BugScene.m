//
//  BugScene.m
//  Disasteroids2
//
//  Created by Scott Lembcke on 10/18/13.
//  Copyright 2013 Cocos2D. All rights reserved.
//

#import "BugScene.h"


@interface Square : CCLayerColor

@property(nonatomic, copy) NSString *name;

@end


@implementation Square

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for(UITouch *touch in touches){
		NSLog(@"Touch %p began in %@", touch, self.name);
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for(UITouch *touch in touches){
		NSLog(@"Touch %p ended in %@", touch, self.name);
	}
}

-(void)draw
{
	[super draw];
}

@end


@implementation BugScene

-(void)onEnter
{
	[super onEnter];
	
	{
		Square *square = [[Square alloc] initWithColor:ccc4(255, 0, 0, 255) width:300 height:300];
		square.position = ccp(100, 200);
		square.name = @"left";
		[self addChild:square];
	}{
		Square *square = [[Square alloc] initWithColor:ccc4(0, 255, 0, 255) width:300 height:300];
		square.position = ccp(600, 200);
		square.name = @"right";
		[self addChild:square];
	}
}

@end
