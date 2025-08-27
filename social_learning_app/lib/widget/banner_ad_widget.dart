import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final bool showLoadingIndicator;

  const BannerAdWidget({
    super.key,
    this.height = 50,
    this.margin,
    this.showLoadingIndicator = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Delay loading to avoid MediaQuery issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerAd();
    });
  }

  Future<void> _loadBannerAd() async {
    if (!AdService.isInitialized) {
      setState(() {
        _errorMessage = 'Ad service not ready';
      });
      return;
    }

    setState(() {
      _isAdLoading = true;
      _errorMessage = null;
    });

    try {
      final adService = AdService.instance();
      final bannerAd = await adService.createAnchoredAdaptiveBanner(
        context: context,
      );

      if (bannerAd != null) {
        // Load the ad before setting it as loaded
        await bannerAd.load();

        if (mounted) {
          setState(() {
            _bannerAd = bannerAd;
            _isAdLoaded = true;
            _isAdLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to create banner ad';
            _isAdLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading ad: $e';
          _isAdLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isInitialized) {
      return _buildPlaceholder('Ad service not ready');
    }

    if (_isAdLoading && widget.showLoadingIndicator) {
      return _buildPlaceholder('Loading ad...', showLoading: true);
    }

    if (_errorMessage != null) {
      return _buildPlaceholder(_errorMessage!);
    }

    // Only show AdWidget if the ad is loaded and ready
    if (_bannerAd != null && _isAdLoaded) {
      return Container(
        margin: widget.margin,
        height: widget.height,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return _buildPlaceholder('Ad not available');
  }

  Widget _buildPlaceholder(String message, {bool showLoading = false}) {
    return Container(
      margin: widget.margin,
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            if (showLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              // Wrap text to prevent overflow
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
