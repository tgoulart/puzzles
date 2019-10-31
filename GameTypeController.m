//
//  GameTypeController.m
//  Puzzles
//
//  Created by Greg Hewgill on 11/03/13.
//  Copyright (c) 2013 Greg Hewgill. All rights reserved.
//

#import "GameTypeController.h"

#import "GameHelpController.h"

@interface GameTypeController ()

@end

@implementation GameTypeController {
    const game *thegame;
    midend *me;
    struct preset_menu *presets;
    int num_presets;
    GameView *gameview;
}

int hacky_count_presets(struct preset_menu* presets) {
    if (presets == NULL) { return 1; }
    int total = 0;
    for (int i = 0; i < presets->n_entries; i++)
        total += hacky_count_presets(presets->entries[i].submenu);
    return total;
}

// Pretends that presets are still a flat menu.  Returns -1 on success.
NSInteger hacky_fetch_preset(struct preset_menu* presets, NSInteger row, struct preset_menu_entry** result) {
    if (presets == NULL) { return row; }
    for (int i = 0; row >= 0 && i < presets->n_entries; i++) {
        if (presets->entries[i].params != NULL) {
            if (row == 0) *result = &presets->entries[i];
            row -= 1;
        } else {
            row = hacky_fetch_preset(presets->entries[i].submenu, row, result);
        }
    }
    return row;
}

- (id)initWithGame:(const game *)game midend:(midend *)m gameview:(GameView *)gv
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        thegame = game;
        me = m;
        presets = midend_get_presets(m, NULL);
        num_presets = hacky_count_presets(presets);
        gameview = gv;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Game Type";

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(showHelp)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section: the number of presets, plus a fixed "Custom" option.
    return num_presets + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (indexPath.row < num_presets) {
        struct preset_menu_entry *entry;
        hacky_fetch_preset(presets, indexPath.row, &entry);
        cell.textLabel.text = [NSString stringWithUTF8String:entry->title];
        if (indexPath.row == midend_which_preset(me)) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    } else {
        cell.textLabel.text = @"Custom";
        if (midend_which_preset(me) < 0) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)showHelp
{
    [self.navigationController pushViewController:[[GameHelpController alloc] initWithFile:[NSString stringWithFormat:@"%s.html", thegame->htmlhelp_topic]] animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    if (indexPath.row < num_presets) {
        struct preset_menu_entry *entry;
        NSInteger r = hacky_fetch_preset(presets, indexPath.row, &entry);
        NSAssert(r == -1, @"A preset should always be found");
        midend_set_params(me, entry->params);
        [gameview startNewGame];
        // bit of a hack here, gameview.nextResponder is actually the view controller we want
        [self.navigationController popToViewController:(UIViewController *)gameview.nextResponder animated:YES];
    } else {
        char *wintitle;
        config_item *config = midend_get_config(me, CFG_SETTINGS, &wintitle);
        [self.navigationController pushViewController:[[GameSettingsController alloc] initWithGame:thegame config:config type:CFG_SETTINGS title:[NSString stringWithUTF8String:wintitle] delegate:self] animated:YES];
        free(wintitle);
    }
}

- (void)didApply:(config_item *)config
{
    const char *msg = midend_set_config(me, CFG_SETTINGS, config);
    if (msg) {
        [[[UIAlertView alloc] initWithTitle:@"Puzzles" message:[NSString stringWithUTF8String:msg] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
    } else {
        [gameview startNewGame];
        // bit of a hack here, gameview.nextResponder is actually the view controller we want
        [self.navigationController popToViewController:(UIViewController *)gameview.nextResponder animated:YES];
    }
}

@end
