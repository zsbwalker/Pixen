//
//  PXPaletteController.m
//  Pixen
//
//  Copyright 2005-2011 Pixen Project. All rights reserved.
//

#import "PXPaletteController.h"

#import "PXCanvas.h"
#import "PXCanvas_Layers.h"
#import "PXDocument.h"
#import "PXPalette.h"
#import "PXPaletteView.h"
#import "PXToolPaletteController.h"
#import "PXToolSwitcher.h"

@interface PXPaletteController ()

- (void)refreshPalette:(NSNotification *)note;
- (void)updatePalette:(NSNotification *)note;

@end


@implementation PXPaletteController
{
	PXPaletteMode _mode;
	PXPalette *_frequencyPalette, *_recentPalette;
}

#define RECENT_LIMIT 32

@synthesize document = _document, paletteView = _paletteView;

- (id)init
{
	self = [super initWithNibName:@"PXPaletteController" bundle:nil];
	
	_frequencyPalette = [[PXPalette alloc] initWithoutBackgroundColor];
	_recentPalette = [[PXPalette alloc] initWithoutBackgroundColor];
	_mode = PXPaletteModeFrequency;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refreshPalette:)
												 name:@"PXCanvasFrequencyPaletteRefresh"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updatePalette:)
												 name:@"PXCanvasPaletteUpdate"
											   object:nil];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_frequencyPalette release];
	[_recentPalette release];
	[super dealloc];
}

- (void)awakeFromNib
{
	_paletteView.highlightEnabled = NO;
}

- (void)setDocument:(PXDocument *)document
{
	if (_document != document)
	{
		_document = document;
		
		[_paletteView setDocument:document];
		[self refreshPalette:nil];
	}
}

- (void)addRecentColor:(NSColor *)color
{
	NSUInteger idx = [_recentPalette indexOfColor:color];
	
	if (idx != NSNotFound)
	{
		if (idx != 0) {
			[_recentPalette removeColorAtIndex:idx];
			[_recentPalette insertColor:color atIndex:0];
		}
	}
	else
	{
		[_recentPalette insertColor:color atIndex:0];
		
		while ([_recentPalette colorCount] > RECENT_LIMIT)
		{
			[_recentPalette removeLastColor];
		}
	}
}

- (void)refreshPalette:(NSNotification *)note
{
	if (![_document containsCanvas:[note object]])
		return;
	
	[_frequencyPalette release];
	_frequencyPalette = [[note object] newFrequencyPalette];
	
	if (_mode == PXPaletteModeFrequency)
	{
		[_paletteView setPalette:_frequencyPalette];
	}
}

- (void)updatePalette:(NSNotification *)note
{
	if (![_document containsCanvas:[note object]])
		return;
	
	NSDictionary *changes = [note userInfo];
	
	NSCountedSet *oldC = [changes objectForKey:@"PXCanvasPaletteUpdateRemoved"];
	NSCountedSet *newC = [changes objectForKey:@"PXCanvasPaletteUpdateAdded"];
	
	for (NSColor *old in oldC)
	{
		[_frequencyPalette decrementCountForColor:old byAmount:[oldC countForObject:old]];
	}
	
	//can do 'recent palette' stuff here too. most draws will consist of one new and many old, so just consider the last 100 new?
	
	for (NSColor *new in newC)
	{
		[_frequencyPalette incrementCountForColor:new byAmount:[newC countForObject:new]];
		[self addRecentColor:new];
	}
	
	[_paletteView setNeedsRetile];
}

- (void)useColorAtIndex:(NSUInteger)index
{
	PXToolSwitcher *switcher = nil;
	
	//FIXME: decouple this
	if ([NSEvent pressedMouseButtons] == 2 || ([NSEvent modifierFlags] & NSControlKeyMask))
	{
		switcher = [[PXToolPaletteController sharedToolPaletteController] rightSwitcher];
	}
	else
	{
		switcher = [[PXToolPaletteController sharedToolPaletteController] leftSwitcher];
	}
	
	[switcher setColor:[_frequencyPalette colorAtIndex:index]];
}

- (void)paletteViewSizeChangedTo:(NSControlSize)size
{
	[[NSUserDefaults standardUserDefaults] setInteger:size
											   forKey:PXColorPickerPaletteViewSizeKey];
}

- (BOOL)isPaletteIndexKey:(NSEvent *)event
{
	NSString *chars = [event characters];
	
	// not sure why numpad is unacceptable, but whatever
	BOOL numpad = [event modifierFlags] & NSNumericPadKeyMask;
	
	return (([chars integerValue] != 0) || ([chars characterAtIndex:0] == '0')) && !numpad;
}

- (void)keyDown:(NSEvent *)event
{
	NSString *chars = [event characters];
	NSUInteger index = [chars integerValue];
	
	[self useColorAtIndex:index];
}

- (IBAction)useMostRecentColors:(id)sender
{
	_mode = PXPaletteModeRecent;
	[_paletteView setPalette:_recentPalette];
}

- (IBAction)useMostFrequentColors:(id)sender
{
	_mode = PXPaletteModeFrequency;
	[_paletteView setPalette:_frequencyPalette];
}

@end
