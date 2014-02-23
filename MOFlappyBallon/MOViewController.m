//
//  MOViewController.m
//  MOFlappyBallon
//
//  Created by minsOne on 2014. 2. 23..
//  Copyright (c) 2014년 minsOne. All rights reserved.
//

#import "MOViewController.h"

@interface MOViewController ()

@property (nonatomic, strong) UIView *balloon;
@property (nonatomic, strong) UIView *ground;
@property (nonatomic, strong) NSMutableArray *scenery;

@property (nonatomic, strong) UIPushBehavior *floatUp;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, assign) NSTimeInterval lastTime;

@end

const CGFloat minHeight = 150; //the minimum building height
const CGFloat maxHeight = 300; //the maximum building height
const CGFloat gap = 150; //the gap between buildings and clouds
const CGFloat scrollSpeed = 100; //the speed at which the level scrolls


@implementation MOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //배경화면 붙이기
    UIImage *backgroundImage = [UIImage imageNamed:@"Background"];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView.layer.magnificationFilter = kCAFilterNearest;
    NSLog(@"%lf", self.view.bounds.size.height);
    backgroundView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:backgroundView];
    
    // 바닥 붙이기
    UIImage *groundImage = [UIImage imageNamed:@"Ground"];
    self.ground = [[UIImageView alloc] initWithImage:groundImage];
    self.ground.layer.magnificationFilter = kCAFilterNearest;
    self.ground.frame = CGRectMake(0, self.view.bounds.size.height - 60, 640, 60);
    [self.view addSubview:self.ground];
    
    self.scenery = [NSMutableArray arrayWithObject:self.ground];
    
    //add balloon
    self.balloon = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 50)];
    UIImage *balloonImage = [UIImage imageNamed:@"Balloon"];
    UIImageView *balloonView = [[UIImageView alloc] initWithImage:balloonImage];
    [balloonView.layer setMagnificationFilter:kCAFilterNearest];
    balloonView.frame = CGRectMake(-5, -5, 50, 140);
    [self.balloon addSubview:balloonView];
    self.balloon.center = CGPointMake(50, self.view.bounds.size.height / 2);
    [self.view addSubview:self.balloon];
    
    //set up animator
    self.animator = [[UIDynamicAnimator alloc] init];
    
    //add gravity
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[self.balloon]];
    gravity.magnitude = 0.5;
    [self.animator addBehavior:gravity];
    
    //add floating behavior
    self.floatUp = [[UIPushBehavior alloc] initWithItems:@[self.balloon] mode:UIPushBehaviorModeInstantaneous];
    self.floatUp.pushDirection = CGVectorMake(0, -1);
    self.floatUp.active = NO;
    [self.animator addBehavior:self.floatUp];
    
    //add tap handler
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [self.view addGestureRecognizer:tapGesture];
    
    //add custom behavior
    UIDynamicBehavior *scroll = [[UIDynamicBehavior alloc] init];
    scroll.action = ^{ [self update]; };
    [self.animator addBehavior:scroll];
}

- (void)update
{
    NSLog(@"%lf %lf", self.balloon.frame.origin.x, self.balloon.frame.origin.y);
    //get time since last update
    NSTimeInterval deltaTime = self.animator.elapsedTime - self.lastTime;
    self.lastTime = self.animator.elapsedTime;
    
    //calculate scroll distance
    CGFloat scrollStep = scrollSpeed * deltaTime;
    
    //scroll ground, buildings and clouds
    for (UIView *view in self.scenery)
    {
        view.center = CGPointMake(view.center.x - scrollStep, view.center.y);
    }
    
    //wrap around if necessary
    if (self.ground.frame.origin.x < -self.view.frame.size.width)
    {
        //reset ground position
        self.ground.center = CGPointMake(self.ground.center.x + self.view.frame.size.width, self.ground.center.y);
        
        //remove offscreen clouds and buildings
        for (UIView *view in [self.scenery reverseObjectEnumerator])
        {
            if (view.frame.origin.x + view.frame.size.width < 0)
            {
                [self.scenery removeObject:view];
                [view removeFromSuperview];
            }
        }
        
        //add new buildings and clouds
        [self addBuildingAndClouds];
    }
    
    //check for collision with scenery (bounding box check)
    for (UIView *view in self.scenery)
    {
        if (CGRectIntersectsRect(self.balloon.frame, view.frame))
        {
            //end simulation
            [self.animator removeAllBehaviors];
            
            //game over
            [[[UIAlertView alloc] initWithTitle:@"Game Over" message:nil delegate:self cancelButtonTitle:@"Play Again" otherButtonTitles:nil] show];
            
            break;
        }
    }
}

- (void)tapped
{
    //apply vertical force
    self.floatUp.active = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addBuildingWithOffset:(CGPoint)offset
{
    UIImage *buildingImage = [UIImage imageNamed:@"Building"];
    UIImageView *buildingView = [[UIImageView alloc] initWithImage:buildingImage];
    buildingView.layer.magnificationFilter = kCAFilterNearest;
    buildingView.frame = CGRectMake(offset.x - 40, offset.y, 80, 570);
    [self.view insertSubview:buildingView belowSubview:self.ground];
    [self.scenery addObject:buildingView];
}

- (void)addCloudWithOffset:(CGPoint)offset
{
    UIView *cloud = [[UIView alloc] initWithFrame:CGRectMake(offset.x - 50, offset.y - 560, 100, 560)];
    UIImage *cloudImage = [UIImage imageNamed:@"Cloud"];
    UIImageView *cloudView = [[UIImageView alloc] initWithImage:cloudImage];
    cloudView.layer.magnificationFilter = kCAFilterNearest;
    cloudView.frame = CGRectMake((cloud.frame.size.width - 240) / 2, 0, 240, 570);
    [cloud addSubview:cloudView];
    [self.view addSubview:cloud];
    [self.scenery addObject:cloud];
}

- (void)addBuildingAndClouds
{
    //calculate horizontal position
    CGFloat x = self.ground.frame.origin.x + self.view.frame.size.width * 1.5;
    
    //get random y position
    CGFloat y = self.view.frame.size.height - minHeight - arc4random_uniform(maxHeight - minHeight);
    
    //add building
    [self addBuildingWithOffset:CGPointMake(x, y)];
    
    //add clouds
    [self addCloudWithOffset:CGPointMake(x, y - gap)];
    [self addCloudWithOffset:CGPointMake(x + 160, y - gap - 50)];
}

- (void)reset
{
    //reset simulation
    [self.animator removeAllBehaviors];
    
    //clean up scenery views
    [self.scenery makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.scenery = [NSMutableArray array];
    
    //reset ground start position and add it to scenery array
    self.ground.center = CGPointMake(self.view.frame.size.width, self.ground.center.y);
    [self.scenery addObject:self.ground];
    [self.view insertSubview:self.ground belowSubview:self.balloon];
    
    //reset balloon start position
    self.balloon.center = CGPointMake(50, self.view.bounds.size.height / 2);
    
    //add floating behavior
    self.floatUp = [[UIPushBehavior alloc] initWithItems:@[self.balloon] mode:UIPushBehaviorModeInstantaneous];
    self.floatUp.pushDirection = CGVectorMake(0, -0.5);
    self.floatUp.active = NO;
    [self.animator addBehavior:self.floatUp];
    
    //add gravity
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[self.balloon]];
    gravity.magnitude = 0.5;
    [self.animator addBehavior:gravity];
    
    //add initial building and clouds
    [self addBuildingAndClouds];
    
    //add custom behavior
    UIDynamicBehavior *scroll = [[UIDynamicBehavior alloc] init];
    scroll.action = ^{ [self update]; };
    [self.animator addBehavior:scroll];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //start the game, after short delay
    [self performSelector:@selector(reset) withObject:nil afterDelay:0.5];
}

@end
