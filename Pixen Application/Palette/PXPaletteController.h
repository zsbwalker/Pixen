//
//  PXPaletteController.h
//  Pixen
//
//  Copyright 2005-2011 Pixen Project. All rights reserved.
//

@class PXDocument, PXPaletteView;

typedef enum {
	PXPaletteModeRecent,
	PXPaletteModeFrequency
} PXPaletteMode;

@interface PXPaletteController : NSViewController

@property (nonatomic, assign) IBOutlet PXPaletteView *paletteView;

@property (nonatomic, assign) PXDocument *document;

- (BOOL)isPaletteIndexKey:(NSEvent *)event;

- (IBAction)useMostRecentColors:(id)sender;
- (IBAction)useMostFrequentColors:(id)sender;

@end
