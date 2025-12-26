#import "ViewController.h"
#import "LeafyView.h"
#import "ScanlinesView.h"
#import "CustomButton.h"
#import "TapePointerView.h"
#import "MemoryCell.h"
#import <QuartzCore/QuartzCore.h> // For CALayer properties
#import "ImageUtils.h"             // For createNoisyImage()

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
@end

@implementation ViewController {
    // UI Elements
    UITextView *codeTextView, *outputTextView;
    UITextField *prefilledInputField, *inputPromptField;
    UICollectionView *memoryCollectionView;
    CustomButton *controlButtons[12];
    TapePointerView *tapePointerView;
    LeafyView *topPane, *bottomPane;
    UIView *tapeContainerView, *inputPromptView;
    
    // Brainfuck Interpreter State
    NSMutableData *memoryTape;
    NSInteger memoryPointer, programCounter;
    NSString *currentExecutingCode;
    BOOL isRunning;

    // Undo Stack
    NSMutableArray *undoStack;
    
    // Concurrency for Input
    dispatch_semaphore_t inputSemaphore;
    uint8_t inputBuffer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize interpreter state
    inputSemaphore = dispatch_semaphore_create(0);
    memoryTape = [NSMutableData dataWithLength:30000];
    undoStack = [NSMutableArray array];

    [self setupUI];
}

- (void)setupUI {
    // --- Top Pane (Code Input) ---
    topPane = [[LeafyView alloc] initWithFrame:CGRectZero backgroundColor:[UIColor colorWithRed:0.22 green:0.15 blue:0.1 alpha:1]];
    [self.view addSubview:topPane];

    codeTextView = [[UITextView alloc] init];
    codeTextView.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    codeTextView.backgroundColor = [UIColor colorWithRed:0.05 green:0.1 blue:0.05 alpha:1];
    codeTextView.textColor = [UIColor colorWithRed:0.4 green:1 blue:0.4 alpha:1];
    codeTextView.layer.cornerRadius = 4;
    codeTextView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1].CGColor;
    codeTextView.layer.borderWidth = 2;
    codeTextView.layer.shadowColor = codeTextView.textColor.CGColor;
    codeTextView.layer.shadowOffset = CGSizeZero;
    codeTextView.layer.shadowRadius = 4;
    codeTextView.layer.shadowOpacity = 0.8;
    codeTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [topPane addSubview:codeTextView];
    [codeTextView addSubview:[[ScanlinesView alloc] init]];

    // --- Middle Pane (Memory Tape) ---
    tapeContainerView = [[UIView alloc] init];
    tapeContainerView.backgroundColor = [UIColor colorWithPatternImage:createNoisyImage([UIColor colorWithWhite:0.2 alpha:1], 0.3)];
    tapeContainerView.layer.shadowOpacity = 0.6;
    tapeContainerView.layer.shadowOffset = CGSizeMake(0, 3);
    [self.view addSubview:tapeContainerView];

    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(50, 70);
    layout.minimumLineSpacing = 0;
    
    memoryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    memoryCollectionView.dataSource = self;
    memoryCollectionView.delegate = self;
    memoryCollectionView.backgroundColor = [UIColor clearColor];
    memoryCollectionView.showsHorizontalScrollIndicator = NO;
    memoryCollectionView.scrollEnabled = NO; // Controlled programmatically
    [memoryCollectionView registerClass:[MemoryCell class] forCellWithReuseIdentifier:@"Cell"];
    [tapeContainerView addSubview:memoryCollectionView];

    tapePointerView = [[TapePointerView alloc] initWithFrame:CGRectMake(0, 0, 54, 74)];
    [self.view addSubview:tapePointerView];

    // --- Bottom Pane (Output & Controls) ---
    bottomPane = [[LeafyView alloc] initWithFrame:CGRectZero backgroundColor:[UIColor colorWithRed:0.1 green:0.06 blue:0.04 alpha:1]];
    [self.view addSubview:bottomPane];
    
    outputTextView = [[UITextView alloc] init];
    outputTextView.editable = NO;
    outputTextView.font = [UIFont fontWithName:@"Courier" size:14];
    outputTextView.backgroundColor = [UIColor blackColor];
    outputTextView.textColor = [UIColor greenColor];
    outputTextView.layer.cornerRadius = 4;
    outputTextView.layer.borderWidth = 2;
    outputTextView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    outputTextView.layer.shadowColor = outputTextView.textColor.CGColor;
    outputTextView.layer.shadowOffset = CGSizeZero;
    outputTextView.layer.shadowRadius = 4;
    outputTextView.layer.shadowOpacity = 0.8;
    [bottomPane addSubview:outputTextView];
    [outputTextView addSubview:[[ScanlinesView alloc] init]];

    prefilledInputField = [[UITextField alloc] init];
    prefilledInputField.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.85 alpha:1];
    prefilledInputField.font = [UIFont fontWithName:@"Courier" size:14];
    prefilledInputField.placeholder = @" IN";
    prefilledInputField.borderStyle = UITextBorderStyleBezel;
    [bottomPane addSubview:prefilledInputField];

    // --- Control Buttons ---
    NSArray *titles = @[@"+", @"-", @"<", @">", @".", @",", @"[", @"]", @"RUN", @"STEP", @"UNDO", @"RST"];
    for (int i = 0; i < 12; i++) {
        controlButtons[i] = [CustomButton buttonWithTitle:titles[i] tag:i];
        [controlButtons[i] addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [bottomPane addSubview:controlButtons[i]];
    }

    // --- Input Prompt Modal ---
    inputPromptView = [[UIView alloc] init];
    inputPromptView.backgroundColor = [UIColor colorWithPatternImage:createNoisyImage([UIColor colorWithRed:0.9 green:0.88 blue:0.82 alpha:1], 0.2)];
    inputPromptView.layer.cornerRadius = 8;
    inputPromptView.layer.borderColor = [UIColor grayColor].CGColor;
    inputPromptView.layer.borderWidth = 2;
    inputPromptView.layer.shadowColor = [UIColor blackColor].CGColor;
    inputPromptView.layer.shadowOpacity = 0.5;
    inputPromptView.layer.shadowOffset = CGSizeMake(0, 5);
    inputPromptView.hidden = YES;
    [self.view addSubview:inputPromptView];
    
    UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 200, 30)];
    promptLabel.text = @"INPUT REQUIRED";
    promptLabel.textAlignment = NSTextAlignmentCenter;
    promptLabel.font = [UIFont boldSystemFontOfSize:16];
    [inputPromptView addSubview:promptLabel];
    
    inputPromptField = [[UITextField alloc] initWithFrame:CGRectMake(20, 45, 160, 30)];
    inputPromptField.borderStyle = UITextBorderStyleBezel;
    inputPromptField.backgroundColor = [UIColor whiteColor];
    inputPromptField.delegate = self;
    [inputPromptView addSubview:inputPromptField];

    CustomButton *okButton = [CustomButton buttonWithTitle:@"OK" tag:99];
    okButton.frame = CGRectMake(110, 85, 80, 40);
    [okButton addTarget:self action:@selector(inputPromptOK) forControlEvents:UIControlEventTouchUpInside];
    [inputPromptView addSubview:okButton];

    CustomButton *exitButton = [CustomButton buttonWithTitle:@"Exit" tag:98];
    exitButton.frame = CGRectMake(10, 85, 80, 40);
    [exitButton addTarget:self action:@selector(inputPromptExit) forControlEvents:UIControlEventTouchUpInside];
    [inputPromptView addSubview:exitButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    float width = self.view.bounds.size.width;
    float height = self.view.bounds.size.height;

    // Layout panes
    topPane.frame = CGRectMake(0, 0, width, height * 0.35);
    tapeContainerView.frame = CGRectMake(0, height * 0.35, width, 80);
    bottomPane.frame = CGRectMake(0, height * 0.35 + 80, width, height - (height * 0.35 + 80));
    
    // Layout subviews
    codeTextView.frame = CGRectInset(topPane.bounds, 15, 15);
    ((UIView*)codeTextView.subviews.lastObject).frame = codeTextView.bounds; // Scanlines

    memoryCollectionView.frame = tapeContainerView.bounds;
    float inset = (width / 2.0) - (50.0 / 2.0); // Center the target cell
    [memoryCollectionView setContentInset:UIEdgeInsetsMake(0, inset, 0, inset)];
    tapePointerView.center = tapeContainerView.center;

    float bottomWidth = bottomPane.bounds.size.width;
    float bottomHeight = bottomPane.bounds.size.height;
    outputTextView.frame = CGRectMake(10, 12, bottomWidth * 0.35, bottomHeight - 55);
    ((UIView*)outputTextView.subviews.lastObject).frame = outputTextView.bounds; // Scanlines
    prefilledInputField.frame = CGRectMake(10, bottomHeight - 38, bottomWidth * 0.35, 26);

    // Layout keyboard buttons
    float keyX = bottomWidth * 0.35 + 15;
    float keyWidth = (bottomWidth - keyX - 10) / 4;
    float keyHeight = (bottomHeight - 24) / 3;
    for (int i = 0; i < 12; i++) {
        controlButtons[i].frame = CGRectMake(keyX + (i % 4) * keyWidth, 12 + (i / 4) * keyHeight, keyWidth - 4, keyHeight - 4);
    }
    
    inputPromptView.frame = CGRectMake(width / 2 - 100, height / 2 - 70, 200, 140);
    
    [self scrollToCurrentMemoryCell];
}

#pragma mark - UICollectionView DataSource & Delegate

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return memoryTape.length;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    MemoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    uint8_t value = ((uint8_t*)memoryTape.bytes)[indexPath.item];
    [cell configureWithIndex:(int)indexPath.item value:value];
    return cell;
}

#pragma mark - Actions

- (void)saveStateForUndo {
    NSDictionary *state = @{
        @"memory": [memoryTape copy],
        @"pointer": @(memoryPointer),
        @"counter": @(programCounter),
        @"output": outputTextView.text
    };
    [undoStack addObject:state];
    // Limit undo history to 50 steps
    if (undoStack.count > 50) {
        [undoStack removeObjectAtIndex:0];
    }
}

- (void)buttonTapped:(CustomButton*)button {
    int tag = (int)button.tag;
    
    if (tag < 8) { // BF operator buttons
        NSRange range = codeTextView.selectedRange;
        if (range.location == NSNotFound) range.location = codeTextView.text.length;
        NSString *newText = [NSString stringWithFormat:@"%@%@%@",
                             [codeTextView.text substringToIndex:range.location],
                             button.titleLabel.text,
                             [codeTextView.text substringFromIndex:range.location]];
        codeTextView.text = newText;
        codeTextView.selectedRange = NSMakeRange(range.location + 1, 0);
    } else if (tag == 8) { // RUN/STOP
        if (isRunning) {
            isRunning = NO;
            [button setTitle:@"RUN" forState:UIControlStateNormal];
        } else {
            [self saveStateForUndo];
            isRunning = YES;
            currentExecutingCode = codeTextView.text;
            [button setTitle:@"STOP" forState:UIControlStateNormal];
            [self runProgram];
        }
    } else if (tag == 9) { // STEP
        if(isRunning) return; // Prevent stepping while running
        currentExecutingCode = codeTextView.text;
        [self saveStateForUndo];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self stepExecution];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateUI];
            });
        });
    } else if (tag == 10) { // UNDO
        if (undoStack.count > 0) {
            NSDictionary *state = undoStack.lastObject;
            memoryTape = [state[@"memory"] mutableCopy];
            memoryPointer = [state[@"pointer"] intValue];
            programCounter = [state[@"counter"] intValue];
            outputTextView.text = state[@"output"];
            [undoStack removeLastObject];
            [self updateUI];
        }
    } else if (tag == 11) { // RESET
        memoryTape = [NSMutableData dataWithLength:30000];
        memoryPointer = 0;
        programCounter = 0;
        outputTextView.text = @"";
        [undoStack removeAllObjects];
        isRunning = NO;
        [controlButtons[8] setTitle:@"RUN" forState:UIControlStateNormal];
        [self updateUI];
    }
}

- (void)inputPromptOK {
    if (inputPromptField.text.length > 0) {
        inputBuffer = [inputPromptField.text characterAtIndex:0];
        inputPromptField.text = @"";
        inputPromptView.hidden = YES;
        [inputPromptField resignFirstResponder];
        dispatch_semaphore_signal(inputSemaphore); // Signal that input is ready
    }
}

- (void)inputPromptExit {
    inputBuffer = 0; // EOF
    inputPromptView.hidden = YES;
    [inputPromptField resignFirstResponder];
    dispatch_semaphore_signal(inputSemaphore);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self inputPromptOK];
    return YES;
}

#pragma mark - UI Updates

- (void)updateUI {
    [self scrollToCurrentMemoryCell];
    [memoryCollectionView reloadData];
}

- (void)scrollToCurrentMemoryCell {
    CGFloat xOffset = (memoryPointer * 50.0) - (memoryCollectionView.bounds.size.width / 2.0) + 25.0;
    CGPoint offset = CGPointMake(xOffset, -memoryCollectionView.contentInset.top);
    [memoryCollectionView setContentOffset:offset animated:YES];
}

#pragma mark - Interpreter Logic

- (void)runProgram {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (self->isRunning) {
            if (self->programCounter >= self->currentExecutingCode.length) {
                // Program finished
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self->controlButtons[8] setTitle:@"RUN" forState:UIControlStateNormal];
                    self->isRunning = NO;
                });
                break;
            }
            
            [self stepExecution];
            [NSThread sleepForTimeInterval:0.002]; // Small delay to allow UI to be responsive

            // Update UI periodically, not on every step, for performance
            if (self->programCounter % 5 == 0) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self updateUI];
                });
            }
        }
        
        // Final UI update after run completes
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateUI];
        });
    });
}

// Executes a single Brainfuck instruction. Can be called from any thread.
- (void)stepExecution {
    if (programCounter >= currentExecutingCode.length) return;
    
    uint8_t *memoryBytes = memoryTape.mutableBytes;
    unichar instruction = [currentExecutingCode characterAtIndex:programCounter];

    switch (instruction) {
        case '>':
            memoryPointer++;
            if (memoryPointer >= memoryTape.length) {
                // Dynamically increase memory tape if pointer goes out of bounds
                [memoryTape increaseLengthBy:1024];
                memoryBytes = memoryTape.mutableBytes; // Re-fetch pointer after reallocation
            }
            break;
        case '<':
            if (memoryPointer > 0) memoryPointer--;
            break;
        case '+':
            memoryBytes[memoryPointer]++;
            break;
        case '-':
            memoryBytes[memoryPointer]--;
            break;
        case '.': { // Scope block to contain the dispatch_async block
            // Output must be done on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self->outputTextView.text = [self->outputTextView.text stringByAppendingFormat:@"%c", memoryBytes[self->memoryPointer]];
                [self->outputTextView scrollRangeToVisible:NSMakeRange(self->outputTextView.text.length, 1)];
            });
            break;
        }
        case ',': {
            __block BOOL needsModalInput = NO;
            // Check for pre-filled input first
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (self->prefilledInputField.text.length > 0) {
                    memoryBytes[self->memoryPointer] = [self->prefilledInputField.text characterAtIndex:0];
                    self->prefilledInputField.text = [self->prefilledInputField.text substringFromIndex:1];
                } else {
                    needsModalInput = YES;
                }
            });

            if (needsModalInput) {
                // Show modal prompt and wait for user input
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->inputPromptView.hidden = NO;
                    [self->inputPromptField becomeFirstResponder];
                });
                // Block this background thread until the semaphore is signaled
                dispatch_semaphore_wait(inputSemaphore, DISPATCH_TIME_FOREVER);
                memoryBytes[memoryPointer] = inputBuffer;
            }
            break;
        }
        case '[': { // Scope block to contain the bracketDepth variable
            if (memoryBytes[memoryPointer] == 0) {
                // Jump forward to the matching ']'
                int bracketDepth = 1;
                while (bracketDepth > 0 && ++programCounter < currentExecutingCode.length) {
                    unichar nextChar = [currentExecutingCode characterAtIndex:programCounter];
                    if (nextChar == '[') bracketDepth++;
                    else if (nextChar == ']') bracketDepth--;
                }
            }
            break;
        }
        case ']': { // Scope block to contain the bracketDepth variable
            if (memoryBytes[memoryPointer] != 0) {
                // Jump backward to the matching '['
                int bracketDepth = 1;
                while (bracketDepth > 0 && programCounter > 0) {
                    programCounter--;
                    unichar prevChar = [currentExecutingCode characterAtIndex:programCounter];
                    if (prevChar == ']') bracketDepth++;
                    else if (prevChar == '[') bracketDepth--;
                }
            }
            break;
        }
    }
    programCounter++;
}

@end
