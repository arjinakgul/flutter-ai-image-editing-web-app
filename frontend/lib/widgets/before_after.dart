import 'package:flutter/material.dart';

/// A widget that displays before and after images side by side
class BeforeAfter extends StatelessWidget {
  final String beforeImageUrl;
  final String? afterImageUrl;
  final double? height;
  final double spacing;
  final bool showLabels;
  final int selectedIndex;
  final Function(int) onSelected;

  const BeforeAfter({
    super.key,
    required this.beforeImageUrl,
    this.afterImageUrl,
    this.height = 200,
    this.spacing = 16,
    this.showLabels = true,
    this.selectedIndex = -1,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Before image
        Expanded(
          child: _buildImageCard(
            context: context,
            imageUrl: beforeImageUrl,
            label: 'Before',
            isAfter: false,
            isSelected: selectedIndex == 0,
            onSelected: () => onSelected(0),
          ),
        ),
        SizedBox(width: spacing),
        // After image
        Expanded(
          child: afterImageUrl != null
              ? _buildImageCard(
                  context: context,
                  imageUrl: afterImageUrl,
                  label: 'After',
                  isAfter: true,
                  isSelected: selectedIndex == 1,
                  onSelected: () => onSelected(1),
                )
              : _buildSkeletonLoader(context, 'After'),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, String label) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabels)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[900],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: showLabels ? Radius.zero : const Radius.circular(14),
                topRight: showLabels ? Radius.zero : const Radius.circular(14),
                bottomLeft: const Radius.circular(14),
                bottomRight: const Radius.circular(14),
              ),
              child: _ShimmerLoader(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required BuildContext context,
    required String? imageUrl,
    required String label,
    required bool isAfter,
    required bool isSelected,
    required Function() onSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[200]!,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          if (isSelected) ...[
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLabels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [Colors.blue[50]!, Colors.blue[100]!]
                          : [Colors.grey[50]!, Colors.grey[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? Colors.blue[900]
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: showLabels
                        ? Radius.zero
                        : const Radius.circular(14),
                    topRight: showLabels
                        ? Radius.zero
                        : const Radius.circular(14),
                    bottomLeft: const Radius.circular(14),
                    bottomRight: const Radius.circular(14),
                  ),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.fitHeight,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      // Show skeleton loader for after image while loading
                      if (isAfter) {
                        return _ShimmerLoader();
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading animation widget
class _ShimmerLoader extends StatefulWidget {
  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.blue[100]!,
                Colors.purple[50]!,
                Colors.blue[100]!,
                Colors.blue[50]!,
              ],
              stops: [
                0.0,
                0.35 + (_animation.value * 0.15),
                0.5 + (_animation.value * 0.15),
                0.65 + (_animation.value * 0.15),
                1.0,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 40,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    'Generating...',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
