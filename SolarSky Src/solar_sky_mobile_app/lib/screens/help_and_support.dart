import 'package:flutter/material.dart';

/*
This page is used to display the help and support information to the user.
The user can find instructions on how to add and expand a virtual farm.
 */
class HelpAndSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0XFF2F004F),
        title: const Text('Help and Support',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Instructions for Adding a Virtual Farm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '1. Tap a grid cell to select the location for a new solar panel.\n'
                '2. Enter the solar panel’s serial number in the field that appears.\n'
                '3. Press \'Confirm\' to save the serial number to the selected grid.\n'
                '4. If you need to edit or remove a serial number, tap the grid cell again. You will be presented with two options: \'Edit\' to change the serial number or \'Delete\' to remove it.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Instructions for Expanding a Virtual Farm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '1. To add a new solar panel, tap an empty grid cell and enter the panel\'s serial number in the field provided.\n'
                '2. After entering the serial number, press \'Confirm\' to save and place the solar panel in the grid.\n'
                '3. To change the status of a faulty panel, tap the panel to display options, then select \'Mark as Maintained\' to update its status to healthy, or \'Delete\' to remove the panel.\n'
                '4. For a healthy panel, tapping it will give you the option to \'Delete\' should you wish to remove it.\n'
                '5. If a panel is deleted, the space becomes available to add a new panel by repeating step 1.\n'
                '6. To expand the farm, use the \'Add Row\' or \'Add Column\' buttons which will appear when there are no more empty spaces in the current grid.\n'
                '7. Rows or columns with panels cannot be deleted. If you wish to shrink the farm, first ensure that all panels in the row or column have been deleted.\n'
                '8. Confirm all changes by pressing \'Save Changes\'.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
