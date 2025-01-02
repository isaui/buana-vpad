import 'dart:async';
import 'package:flutter/material.dart';
import 'package:buana_vpad/database/db_helper.dart';
import 'package:buana_vpad/models/button_state.dart';
import 'package:buana_vpad/models/controller_layout.dart';
import 'package:buana_vpad/models/controller_state.dart';
import 'package:buana_vpad/models/dpad_layout.dart';
import 'package:buana_vpad/models/dpad_state.dart';
import 'package:buana_vpad/models/joystick_layout.dart';
import 'package:buana_vpad/models/button_layout.dart';
import 'package:buana_vpad/models/joystick_state.dart';
import 'package:buana_vpad/utils/layout_percentage.dart';
import 'package:buana_vpad/widgets/controller_widget.dart';
import 'package:buana_vpad/enums/button_shape.dart';
import 'package:uuid/uuid.dart';

class ControllerPreviewPage extends StatefulWidget {
  final String? layoutId;
  final bool isStatic;
  final double? maxWidth;
  final double? maxHeight;
  final ControllerLayout? initialLayout;

  const ControllerPreviewPage(
      {super.key,
      this.layoutId,
      this.isStatic = false,
      this.maxWidth,
      this.maxHeight,
      this.initialLayout});

  @override
  State<ControllerPreviewPage> createState() => _ControllerPreviewPageState();
}

class _ControllerPreviewPageState extends State<ControllerPreviewPage> {
  late ControllerLayout layout;
  late ControllerState state;
  bool showDebug = true;
  late TextEditingController nameController;
  bool isEditing = false;
  final dbHelper = DatabaseHelper();
  final uuid = const Uuid();
  bool isLoading = true;
  bool _showSidebar = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    state = _createInitialState();
    nameController = TextEditingController(text: 'New Controller Layout');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only load layout on first build
    if (!_initialized) {
      _loadLayout();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  ControllerLayout _transformLayout(ControllerLayout sourceLayout) {
    final newSize = Size(widget.maxWidth!, widget.maxHeight!);
    // Perlu di-convert ke current size preview card
    return LayoutPercentage.convertLayoutToCurrentScreen(
      sourceLayout,
      newSize,
    );
  }

  Future<void> _loadLayout() async {
    setState(() => isLoading = true);
    try {
      if (widget.initialLayout != null) {
        // Transform initial layout untuk preview mode
        setState(() {
          layout = _transformLayout(widget.initialLayout!);
          nameController.text = widget.initialLayout!.name;
        });
      } else if (widget.layoutId != null) {
        // Edit mode - load existing layout
        final savedLayout =
            await dbHelper.getControllerLayout(widget.layoutId!);
        if (savedLayout != null) {
          // ignore: use_build_context_synchronously
          final currentScreenSize = MediaQuery.of(context).size;
          final convertedLayout = LayoutPercentage.convertLayoutToCurrentScreen(
            savedLayout,
            currentScreenSize,
          );

          setState(() {
            layout = convertedLayout;
            nameController.text = savedLayout.name;
          });
        }
      } else {
        // Create mode - use default layout
        setState(() {
          layout = _createDefaultLayout();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading layout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Fallback to default layout if error
      setState(() {
        layout = _createDefaultLayout();
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    try {
      // Update layout dengan name baru tapi ID tetap
      final layoutToSave = layout.copyWith(
          newName: nameController.text.trim(), newIsEditable: false);

      await dbHelper.insertControllerLayout(layoutToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layout "${layoutToSave.name}" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving layout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.layoutId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layout'),
        content: Text('Are you sure you want to delete "${layout.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dbHelper.deleteControllerLayout(widget.layoutId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layout deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting layout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleStateChange(ControllerState newState) {
    setState(() {
      state = newState;
    });
  }

  void _handleLayoutChange(ControllerLayout newLayout) {
    setState(() {
      layout = newLayout;
    });
  }

  ControllerLayout _createDefaultLayout() {
    final screenSize = widget.isStatic
        ? Size(widget.maxWidth!, widget.maxHeight!)
        : MediaQuery.of(context).size;
    final layoutId = uuid.v4();
    final layoutPercentage = LayoutPercentage(
      screenWidth: screenSize.width,
      screenHeight: screenSize.height,
    );
    final raw = {
      'zones': <String, double>{
        'centerX': 50.0,
        'leftSide': 15.0,
        'rightSide': 85.0,
        'topMargin': 12.0,
      },
      'verticalZones': <String, double>{
        'triggerY': 15.0,
        'menuY': 30.0,
        'mainButtonY': 45.0, // ABXY dan left joystick
        'secondaryY': 70.0, // dpad dan right joystick
      },
      'sizes': <String, dynamic>{
        'mainButtons': <String, double>{
          // ABXY
          'size': 12.0,
          'spacing': 8.0,
        },
        'menuButtons': <String, double>{
          // Start/Select
          'size': 12.0,
          'spacing': 8.0,
        },
        'triggers': <String, double>{
          'width': 15.0,
          'height': 8.0,
          'verticalGap': 10.0,
        },
        'joystick': <String, double>{
          'size': 25.0,
        },
        'dpad': <String, double>{
          'size': 25.0,
          'spacing': 25.0,
        },
      },
    };

    // Helper functions
    double getZone(String key) => (raw['zones'] as Map<String, double>)[key]!;
    double getVerticalZone(String key) =>
        (raw['verticalZones'] as Map<String, double>)[key]!;
    double getMainButtonSize(String key) =>
        ((raw['sizes'] as Map<String, dynamic>)['mainButtons']
            as Map<String, double>)[key]!;
    double getMenuButtonSize(String key) =>
        ((raw['sizes'] as Map<String, dynamic>)['menuButtons']
            as Map<String, double>)[key]!;
    double getTriggerSize(String key) =>
        ((raw['sizes'] as Map<String, dynamic>)['triggers']
            as Map<String, double>)[key]!;
    double getJoystickSize() =>
        ((raw['sizes'] as Map<String, dynamic>)['joystick']
            as Map<String, double>)['size']!;
    double getDpadSize(String key) =>
        ((raw['sizes'] as Map<String, dynamic>)['dpad']
            as Map<String, double>)[key]!;

    return ControllerLayout(
      id: layoutId,
      name: 'New Controller Layout',
      width: screenSize.width,
      height: screenSize.height,
      buttons: {
        // Face buttons (ABXY)
        'A': ButtonLayout(
          id: 'A',
          x: layoutPercentage.getAbsoluteX(getZone('rightSide')),
          y: layoutPercentage.getAbsoluteY(
              getVerticalZone('mainButtonY') + getMainButtonSize('spacing')),
          width: layoutPercentage.getAbsoluteSize(getMainButtonSize('size')),
          label: 'A',
          shape: ButtonShape.circle,
        ),
        'B': ButtonLayout(
          id: 'B',
          x: layoutPercentage.getAbsoluteX(
              getZone('rightSide') + getMainButtonSize('spacing')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('mainButtonY')),
          width: layoutPercentage.getAbsoluteSize(getMainButtonSize('size')),
          label: 'B',
          shape: ButtonShape.circle,
        ),
        'X': ButtonLayout(
          id: 'X',
          x: layoutPercentage.getAbsoluteX(
              getZone('rightSide') - getMainButtonSize('spacing')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('mainButtonY')),
          width: layoutPercentage.getAbsoluteSize(getMainButtonSize('size')),
          label: 'X',
          shape: ButtonShape.circle,
        ),
        'Y': ButtonLayout(
          id: 'Y',
          x: layoutPercentage.getAbsoluteX(getZone('rightSide')),
          y: layoutPercentage.getAbsoluteY(
              getVerticalZone('mainButtonY') - getMainButtonSize('spacing')),
          width: layoutPercentage.getAbsoluteSize(getMainButtonSize('size')),
          label: 'Y',
          shape: ButtonShape.circle,
        ),

        // Shoulder buttons
        'LB': ButtonLayout(
          id: 'LB',
          x: layoutPercentage.getAbsoluteX(getZone('leftSide')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('triggerY')),
          width: layoutPercentage.getAbsoluteWidth(getTriggerSize('width')),
          height: layoutPercentage.getAbsoluteHeight(getTriggerSize('height')),
          label: 'LB',
          shape: ButtonShape.rectangle,
          cornerRadius: 20,
        ),
        'RB': ButtonLayout(
          id: 'RB',
          x: layoutPercentage
              .getAbsoluteX(getZone('rightSide') - getTriggerSize('width')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('triggerY')),
          width: layoutPercentage.getAbsoluteWidth(getTriggerSize('width')),
          height: layoutPercentage.getAbsoluteHeight(getTriggerSize('height')),
          label: 'RB',
          shape: ButtonShape.rectangle,
          cornerRadius: 20,
        ),

        // Triggers
        'LT': ButtonLayout(
          id: 'LT',
          x: layoutPercentage.getAbsoluteX(getZone('leftSide')),
          y: layoutPercentage.getAbsoluteY(
              getVerticalZone('triggerY') - getTriggerSize('verticalGap')),
          width: layoutPercentage.getAbsoluteWidth(getTriggerSize('width')),
          height: layoutPercentage.getAbsoluteHeight(getTriggerSize('height')),
          label: 'LT',
          shape: ButtonShape.rectangle,
          cornerRadius: 20,
        ),
        'RT': ButtonLayout(
          id: 'RT',
          x: layoutPercentage
              .getAbsoluteX(getZone('rightSide') - getTriggerSize('width')),
          y: layoutPercentage.getAbsoluteY(
              getVerticalZone('triggerY') - getTriggerSize('verticalGap')),
          width: layoutPercentage.getAbsoluteWidth(getTriggerSize('width')),
          height: layoutPercentage.getAbsoluteHeight(getTriggerSize('height')),
          label: 'RT',
          shape: ButtonShape.rectangle,
          cornerRadius: 20,
        ),

        // Menu buttons
        'Start': ButtonLayout(
          id: 'Start',
          x: layoutPercentage
              .getAbsoluteX(getZone('centerX') + getMenuButtonSize('spacing')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('menuY')),
          width: layoutPercentage.getAbsoluteSize(getMenuButtonSize('size')),
          label: '≡',
          shape: ButtonShape.circle,
        ),
        'Select': ButtonLayout(
          id: 'Select',
          x: layoutPercentage.getAbsoluteX(getZone('centerX') -
              getMenuButtonSize('spacing') -
              getMenuButtonSize('size')),
          y: layoutPercentage.getAbsoluteY(getVerticalZone('menuY')),
          width: layoutPercentage.getAbsoluteSize(getMenuButtonSize('size')),
          label: '⋮',
          shape: ButtonShape.circle,
        ),
      },

      // DPad
      dpadLayout: DPadLayout(
        centerX: layoutPercentage
            .getAbsoluteX(getZone('leftSide') + getDpadSize('spacing')),
        centerY: layoutPercentage.getAbsoluteY(getVerticalZone('secondaryY')),
        size: layoutPercentage.getAbsoluteSize(getDpadSize('size')),
        hapticEnabled: true,
      ),

      // Analog sticks
      leftJoystick: JoystickLayout(
        x: layoutPercentage.getAbsoluteX(getZone('leftSide')),
        y: layoutPercentage.getAbsoluteY(getVerticalZone('mainButtonY')),
        outerSize: layoutPercentage.getAbsoluteSize(getJoystickSize()),
        innerSize: layoutPercentage.getAbsoluteSize(getJoystickSize() * 0.4),
        isDraggable: true,
        deadzone: 0.1,
      ),
      rightJoystick: JoystickLayout(
        x: layoutPercentage
            .getAbsoluteX(getZone('rightSide') - getJoystickSize()),
        y: layoutPercentage.getAbsoluteY(getVerticalZone('secondaryY')),
        outerSize: layoutPercentage.getAbsoluteSize(getJoystickSize()),
        innerSize: layoutPercentage.getAbsoluteSize(getJoystickSize() * 0.4),
        isDraggable: true,
        deadzone: 0.1,
      ),

      isEditable: false,
    );
  }

  ControllerState _createInitialState() {
    return ControllerState(
      buttonStates: {
        'A': ButtonState(isPressed: false, value: 0, id: 'A'),
        'B': ButtonState(isPressed: false, value: 0, id: 'B'),
        'X': ButtonState(isPressed: false, value: 0, id: 'X'),
        'Y': ButtonState(isPressed: false, value: 0, id: 'Y'),
        'LB': ButtonState(isPressed: false, value: 0, id: 'LB'),
        'RB': ButtonState(isPressed: false, value: 0, id: 'RB'),
        'LT': ButtonState(isPressed: false, value: 0, id: 'LT'),
        'RT': ButtonState(isPressed: false, value: 0, id: 'RT'),
        'Start': ButtonState(isPressed: false, value: 0, id: 'Start'),
        'Select': ButtonState(isPressed: false, value: 0, id: 'Select'),
      },
      dpadState: DPadState(),
      leftJoystickState: JoystickState(
        dx: 0,
        dy: 0,
        intensity: 0,
        angle: 0,
        isPressed: false,
      ),
      rightJoystickState: JoystickState(
        dx: 0,
        dy: 0,
        intensity: 0,
        angle: 0,
        isPressed: false,
      ),
    );
  }

  Future<void> _showSaveDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(widget.layoutId == null ? 'Save Layout' : 'Update Layout'),
          content: Text(widget.layoutId == null
              ? 'Are you sure you want to save this layout?'
              : 'Are you sure you want to update this layout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleSave();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      left: 8,
      top: MediaQuery.of(context).padding.top + 8,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: _showSidebar ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with layout name
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: nameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() => isEditing = false);
                                },
                              ),
                            ),
                            onSubmitted: (_) {
                              setState(() => isEditing = false);
                            },
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nameController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => isEditing = true);
                                },
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Edit/Preview Toggle
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        layout = layout.copyWith(
                          newIsEditable: !layout.isEditable,
                        );
                        if (!layout.isEditable) {
                          state = _createInitialState();
                        }
                        _showSidebar = false;
                      });
                    },
                    icon:
                        Icon(layout.isEditable ? Icons.visibility : Icons.edit),
                    label: Text(layout.isEditable ? 'Preview' : 'Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          layout.isEditable ? Colors.amber : Colors.blue[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _showSaveDialog,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  // Delete Button (if editing existing layout)
                  if (widget.layoutId != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _handleDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Debug Panel
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Layout ID: ${layout.id}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Left Joy: ${state.leftJoystickState?.dx.toStringAsFixed(2) ?? "0"}, ${state.leftJoystickState?.dy.toStringAsFixed(2) ?? "0"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Right Joy: ${state.rightJoystickState?.dx.toStringAsFixed(2) ?? "0"}, ${state.rightJoystickState?.dy.toStringAsFixed(2) ?? "0"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active Buttons: ${state.buttonStates.entries.where((e) => e.value.isPressed).map((e) => e.key).join(", ")}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'DPad: ${state.dpadState?.currentDirection ?? "none"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Positioned(
      right: _showSidebar ? 308 : 8,
      top: MediaQuery.of(context).padding.top + 8,
      child: GestureDetector(
        onTap: () => setState(() => _showSidebar = !_showSidebar),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            _showSidebar ? Icons.chevron_right : Icons.chevron_left,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewWidget() {
    if (isLoading) {
      // Return loading indicator dengan ukuran sesuai constraint
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? double.infinity,
          maxHeight: widget.maxHeight ?? double.infinity,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius:
                widget.isStatic ? BorderRadius.circular(8) : BorderRadius.zero,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final previewWidget = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isStatic
              ? [
                  Colors.grey[900]!,
                  Colors.grey[800]!,
                ]
              : [
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                ],
        ),
      ),
      child: ClipRRect(
        borderRadius:
            widget.isStatic ? BorderRadius.circular(8) : BorderRadius.zero,
        child: ControllerWidget(
          layout: layout,
          state: state,
          onStateChanged: widget.isStatic ? null : _handleStateChange,
          onLayoutChanged: widget.isStatic ? null : _handleLayoutChange,
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth ?? double.infinity,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      child: previewWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    print({
      // false - untuk handle drag interactions
      'showDebug': showDebug, // true - untuk show/hide debug panel
      'isEditing': isEditing, // false - untuk edit mode layout name
      'isLoading': isLoading, // true - untuk loading state
      '_showSidebar': _showSidebar, // true - untuk toggle sidebar visibility
    });
    if (widget.isStatic) {
      return _buildPreviewWidget();
    }
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // full width scaffold
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade900,
                  Colors.grey.shade800,
                ],
              ),
            ),
            child: ControllerWidget(
              layout: layout,
              state: state,
              onStateChanged: _handleStateChange,
              onLayoutChanged: _handleLayoutChange,
            ),
          ),

          // Sidebar
          _buildSidebar(),

          // Toggle Button
          _buildToggleButton(),

          _buildBackButton()
        ],
      ),
    );
  }
}
