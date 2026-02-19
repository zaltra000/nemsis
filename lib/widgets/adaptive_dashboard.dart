import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/mobile_constants.dart';
import '../utils/responsive.dart';

class AdaptiveDashboard extends StatelessWidget {
  final double cpu;
  final double ram;
  final int netSent;
  final int netRecv;

  const AdaptiveDashboard({
    super.key,
    required this.cpu,
    required this.ram,
    required this.netSent,
    required this.netRecv,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getAdaptivePadding(context);
    
    if (isMobile) {
      return _buildMobileLayout(context, padding);
    }
    return _buildDesktopLayout(context, padding);
  }

  Widget _buildMobileLayout(BuildContext context, EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard(
            context,
            "CPU LOAD",
            cpu,
            Colors.redAccent,
            Icons.memory,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            context,
            "RAM USAGE",
            ram,
            Colors.blueAccent,
            Icons.storage,
          ),
          const SizedBox(height: 16),
          Text(
            "NETWORK TRAFFIC",
            style: GoogleFonts.outfit(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
              color: MobileConstants.matrixGreen,
            ),
          ),
          const SizedBox(height: 12),
          _buildNetStatCard(
            context,
            "TX (SENT)",
            "${(netSent / 1024).toStringAsFixed(2)} KB",
            Colors.orangeAccent,
            Icons.upload,
          ),
          const SizedBox(height: 8),
          _buildNetStatCard(
            context,
            "RX (RECV)",
            "${(netRecv / 1024).toStringAsFixed(2)} KB",
            Colors.tealAccent,
            Icons.download,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, EdgeInsets padding) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  "CPU LOAD",
                  cpu,
                  Colors.redAccent,
                  Icons.memory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  "RAM USAGE",
                  ram,
                  Colors.blueAccent,
                  Icons.storage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "NETWORK TRAFFIC",
            style: GoogleFonts.outfit(
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: MobileConstants.matrixGreen,
            ),
          ),
          const SizedBox(height: 16),
          _buildNetStatRow(
            context,
            "TX (SENT)",
            "${(netSent / 1024).toStringAsFixed(2)} KB",
            Colors.orangeAccent,
          ),
          _buildNetStatRow(
            context,
            "RX (RECV)",
            "${(netRecv / 1024).toStringAsFixed(2)} KB",
            Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 14);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: MobileConstants.cardBackground,
        borderRadius: BorderRadius.circular(
          isMobile 
            ? MobileConstants.mobileCardBorderRadius 
            : MobileConstants.tabletCardBorderRadius,
        ),
        border: Border.all(
          color: color.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: isMobile ? 20 : 24),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ),
              Text(
                "${value.toStringAsFixed(1)}%",
                style: GoogleFonts.firaCode(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: isMobile ? 6 : 8,
              backgroundColor: Colors.white10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 12);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MobileConstants.cardBackground,
        borderRadius: BorderRadius.circular(MobileConstants.mobileCardBorderRadius),
        border: Border.all(
          color: color.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.firaCode(
                  fontSize: fontSize,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 12);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.firaCode(
              fontSize: fontSize,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
