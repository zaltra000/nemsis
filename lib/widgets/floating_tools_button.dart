import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mobile_constants.dart';
import '../models/tool_item.dart';
import '../utils/responsive.dart';

class FloatingToolsButton extends StatelessWidget {
  final List<ToolItem> tools;
  final Function(String) onToolSelected;

  const FloatingToolsButton({
    super.key,
    required this.tools,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: MobileConstants.matrixGreen,
      onPressed: () => showToolsMenu(context),
      child: const Icon(
        Icons.grid_view,
        color: MobileConstants.darkBackground,
      ),
    );
  }

  void showToolsMenu(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: MobileConstants.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "QUICK TOOLS",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MobileConstants.matrixGreen,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 3 : 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return _buildToolButton(context, tool);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolButton(BuildContext context, ToolItem tool) {
    return Material(
      color: MobileConstants.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onToolSelected(tool.command);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: MobileConstants.matrixGreen.withAlpha(50),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool.icon,
                size: 24,
                color: MobileConstants.matrixGreen,
              ),
              const SizedBox(height: 4),
              Text(
                tool.label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
