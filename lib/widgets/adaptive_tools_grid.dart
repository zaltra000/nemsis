import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mobile_constants.dart';
import '../models/tool_item.dart';
import '../utils/responsive.dart';

class AdaptiveToolsGrid extends StatelessWidget {
  final List<ToolItem> tools;
  final Function(String) onToolSelected;

  const AdaptiveToolsGrid({
    super.key,
    required this.tools,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);
    final padding = ResponsiveUtils.getAdaptivePadding(context);
    
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: _getChildAspectRatio(context),
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildToolCard(context, tool);
      },
    );
  }

  double _getChildAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 2.5;
    if (width < 600) return 1.2;
    if (width < 900) return 1.0;
    return 1.0;
  }

  Widget _buildToolCard(BuildContext context, ToolItem tool) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 12);
    
    return Material(
      color: MobileConstants.cardBackground,
      borderRadius: BorderRadius.circular(
        isMobile 
          ? MobileConstants.mobileCardBorderRadius 
          : MobileConstants.tabletCardBorderRadius,
      ),
      child: InkWell(
        onTap: () => onToolSelected(tool.command),
        borderRadius: BorderRadius.circular(
          isMobile 
            ? MobileConstants.mobileCardBorderRadius 
            : MobileConstants.tabletCardBorderRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: MobileConstants.matrixGreen.withAlpha(50),
            ),
            borderRadius: BorderRadius.circular(
              isMobile 
                ? MobileConstants.mobileCardBorderRadius 
                : MobileConstants.tabletCardBorderRadius,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool.icon,
                size: isMobile ? 28 : 32,
                color: MobileConstants.matrixGreen,
              ),
              const SizedBox(height: 12),
              Text(
                tool.label,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isMobile) ...[
                const SizedBox(height: 4),
                Text(
                  tool.command.length > 20 
                    ? '${tool.command.substring(0, 20)}...' 
                    : tool.command,
                  style: GoogleFonts.firaCode(
                    fontSize: fontSize - 2,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
