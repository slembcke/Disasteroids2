//
//  DisasteroidsLayer.m
//  Disasteroids2
//
//  Created by Scott Lembcke on 10/17/13.
//  Copyright 2013 Cocos2D. All rights reserved.
//

#import "DisasteroidsLayer.h"
#import "CCPhysics+ObjectiveChipmunk.h"

enum Z_ORDER {
	Z_SHIP,
	Z_ASTEROID,
	Z_JOYSTICK,
};


#define JOYSTICK_RADIUS 30.0
#define JOYSTICK_LEFT_CENTER ccp(100, 100)


@interface Joystick : CCNode

@property(nonatomic, readonly) CGPoint value;
@property(nonatomic, assign) float deadZone;

@end


@implementation Joystick {
	CGPoint _center;
	float _radius;
	
	__unsafe_unretained UITouch *_trackingTouch;
}

-(id)initWithCenter:(CGPoint)center radius:(float)radius
{
	if((self = [super init])){
		_center = center;
		_radius = radius;
		
		self.position = center;
		self.contentSize = CGSizeMake(radius*2, radius*2);
		self.anchorPoint = ccp(0.5, 0.5);
		
		CCDrawNode *drawNode = [CCDrawNode node];
		[self addChild:drawNode];
		
		[drawNode drawDot:ccp(radius, radius) radius:radius color:ccc4f(1, 1, 1, 0.5)];
		
		self.userInteractionEnabled = YES;
	}
	
	return self;
}

-(void)setTouchPosition:(CGPoint)touch
{
	CGPoint delta = cpvclamp(cpvsub(touch, _center), _radius);
	
	self.position = cpvadd(_center, delta);
	
	CGPoint value = ccpMult(delta, 1.0/_radius);
	_value = (cpvnear(value, CGPointZero, _deadZone) ? CGPointZero : value);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(_trackingTouch) return;
	
	for(UITouch *touch in touches){
		CGPoint pos = [self.parent convertTouchToNodeSpace:touch];
		if(cpvnear(_center, pos, _radius)){
			_trackingTouch = touch;
			self.touchPosition = pos;
			
			break;
		}
	}
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for(UITouch *touch in touches){
		if(touch == _trackingTouch){
			self.touchPosition = [self.parent convertTouchToNodeSpace:touch];
		}
	}
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	for(UITouch *touch in touches){
		if(touch == _trackingTouch){
			_trackingTouch = nil;
			self.touchPosition = _center;
		}
	}
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEnded:touches withEvent:event];
}

@end


@interface Ship : CCSprite
@end


@implementation Ship {

}

-(id)init
{
	if((self = [super initWithFile:@"Ship1.png"])){
		CGSize size = self.contentSize;
		float radius = 0.8*(size.width + size.height)/4.0;
		
		CCPhysicsBody *body = [CCPhysicsBody bodyWithCircleOfRadius:radius andCenter:self.anchorPointInPoints];
		body.collisionCategories = @[@"ship"];
		body.collisionMask = @[@"asteroids"];
		body.collisionType = @"ship";
		self.physicsBody = body;
	}
	
	return self;
}

@end

@interface Asteroid : CCSprite
@end


@implementation Asteroid

-(id)init
{
	if((self = [super initWithFile:@"Asteroid.png"])){
		CGSize size = self.contentSize;
		float radius = 0.7*(size.width + size.height)/4.0;
		
		CCPhysicsBody *body = [CCPhysicsBody bodyWithCircleOfRadius:radius andCenter:self.anchorPointInPoints];
		body.collisionCategories = @[@"asteroid"];
		body.collisionMask = @[@"ship"];
		body.collisionType = @"asteroid";
		self.physicsBody = body;
	}
	
	return self;
}

@end


@implementation DisasteroidsLayer {
	Ship *_ship;
	NSMutableArray *_asteroids;
	
	Joystick *_leftJoystick, *_rightJoystick;
}

-(id)init
{
	if((self = [super init])){
		self.userInteractionEnabled = YES;
	}
	
	return self;
}

+(CCScene *)scene
{
	CCScene *scene = [CCScene node];
	[scene addChild:[[self alloc] init]];
	
	return scene;
}

-(void)onEnter
{
	[super onEnter];
	
	CCPhysicsNode *physics = [CCPhysicsNode node];
	physics.debugDraw = YES;
	[self addChild:physics];
	
	_leftJoystick = [[Joystick alloc] initWithCenter:JOYSTICK_LEFT_CENTER radius:JOYSTICK_RADIUS];
	[physics addChild:_leftJoystick z:Z_JOYSTICK];
	
	_ship = [[Ship alloc] init];
	_ship.position = ccp(512, 384);
	[physics addChild:_ship z:Z_SHIP];
	
	_asteroids = [NSMutableArray array];
	
	CGSize size = [CCDirector sharedDirector].winSize;
	for(int i=0; i<15; i++){
		Asteroid *asteroid = [Asteroid node];
		asteroid.position = ccp(CCRANDOM_0_1()*size.width, CCRANDOM_0_1()*size.height);
		
		CGPoint randomOnUnitCircle = ccpNormalize(ccp(CCRANDOM_MINUS1_1(), CCRANDOM_MINUS1_1()));
		asteroid.physicsBody.velocity = ccpMult(randomOnUnitCircle, 50);
		
		[physics addChild:asteroid z:Z_ASTEROID];
		[_asteroids addObject:asteroid];
	}
	
	[self scheduleUpdate];
}

static void
Wrap(CCNode *node, CGSize size)
{
	CGPoint p = node.position;
	node.position = ccp(fmodf(p.x + size.width, size.width), fmodf(p.y + size.height, size.height));
}

-(void)updateShip:(ccTime)delta
{
	float speed = 200.0;
	float accelTime = 0.25;
	
	CCPhysicsBody *body = _ship.physicsBody;
	CGPoint targetVelocity = ccpMult(_leftJoystick.value, speed);
	CGPoint velocity = cpvlerpconst(body.velocity, targetVelocity, speed/accelTime*delta);
	
	body.velocity = velocity;
	if(cpvlengthsq(velocity)){
		body.absoluteRadians = atan2f(velocity.y, velocity.x) - M_PI_2;
	}
	
	Wrap(_ship, [CCDirector sharedDirector].winSize);
}

-(void)update:(ccTime)delta
{
	[self updateShip:delta];
	
	CGSize size = [CCDirector sharedDirector].winSize;
	for(Asteroid *asteroid in _asteroids) Wrap(asteroid, size);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"Pew Pew!");
}

@end
