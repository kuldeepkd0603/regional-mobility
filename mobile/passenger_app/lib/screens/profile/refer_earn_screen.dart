import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  static const Color navy = Color(0xFF075675);
  static const Color teal = Color(0xFF159B7C);
  static const Color ink = Color(0xFF151B2B);
  static const Color muted = Color(0xFF68727D);
  static const Color line = Color(0xFFE4E9ED);
  static const Color page = Color(0xFFF8FAFA);

  // UPDATE THESE TWO ASSET PATHS to the actual paths in your project.
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo.png';
  static const String bannerAsset =
      'assets/images/raahi_assets/offers/refer_earn_banner.png';
  static const String skycityAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';

  // Replace these placeholders with values returned by your referral API.
  static const String referralCode = 'N/A';
  static const String referralLink = 'N/A';
  static const String earnings = 'N/A';
  static const String successfulReferrals = 'N/A';

  // Keep this list empty until real referral-history data is connected.
  // Populate it from your API; do not use sample/fake customer details.
  final List<ReferralFriend> invitedFriends = const [];

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyText(String value, String label) async {
    if (value.isEmpty || value == 'N/A') {
      _showMessage('$label is not available yet');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    _showMessage('$label copied');
  }

  Future<void> _shareReferral() async {
    if (referralCode == 'N/A' || referralLink == 'N/A') {
      _showMessage('Your referral link is not available yet');
      return;
    }
    await Clipboard.setData(
      ClipboardData(
        text: 'Join me on Raahi! Use my referral code '
            '$referralCode. $referralLink',
      ),
    );
    _showMessage('Referral invitation copied');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = (size.height / 850).clamp(0.84, 1.0);

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14 * scale, 5, 14 * scale, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(scale),
                    SizedBox(height: 9 * scale),
                    _buildBanner(),
                    SizedBox(height: 8 * scale),
                    _buildReferralDetails(scale),
                    SizedBox(height: 8 * scale),
                    _buildEarnings(scale),
                    SizedBox(height: 10 * scale),
                    _buildHowItWorks(scale),
                    SizedBox(height: 9 * scale),
                    _buildConditions(scale),
                    SizedBox(height: 8 * scale),
                    _buildInvitedFriends(scale),
                  ],
                ),
              ),
            ),
            _buildBottomAction(scale),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: navy,
                size: 25,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                logoAsset,
                height: 44,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: IconButton(
              onPressed: () => _showMessage('Notifications'),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: navy,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Title is intentionally centered, matching the second/reference screenshot.
  Widget _buildTitle(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Refer & Earn',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 23 * scale,
            height: 1.12,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          'Invite friends, they ride, you earn!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 12.5 * scale,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AspectRatio(
        aspectRatio: 3.65,
        child: Image.asset(
          bannerAsset,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF08718A),
            alignment: Alignment.center,
            child: const Text(
              'Refer a Friend & Get ₹100',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralDetails(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _referralValue(
              title: 'Your Referral Code',
              value: referralCode,
              onCopy: () => _copyText(referralCode, 'Referral code'),
              scale: scale,
            ),
          ),
          Container(
            height: 48 * scale,
            width: 1,
            color: line,
            margin: EdgeInsets.symmetric(horizontal: 8 * scale),
          ),
          Expanded(
            child: _referralValue(
              title: 'Your Referral Link',
              value: referralLink,
              onCopy: () => _copyText(referralLink, 'Referral link'),
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referralValue({
    required String title,
    required String value,
    required VoidCallback onCopy,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 10.5 * scale,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5 * scale),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 35 * scale,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FA),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: 29 * scale,
                minHeight: 34 * scale,
              ),
              icon: Icon(
                Icons.copy_rounded,
                color: ink,
                size: 18 * scale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEarnings(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 11 * scale,
        vertical: 9 * scale,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDDF9E9), Color(0xFFE5FAF2)],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _earningItem(
              icon: Icons.card_giftcard_rounded,
              title: 'Your Earnings',
              value: earnings,
              scale: scale,
            ),
          ),
          Container(
            height: 40 * scale,
            width: 1,
            color: teal.withValues(alpha: 0.65),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: _earningItem(
              icon: Icons.groups_rounded,
              title: 'Successful Referrals',
              value: successfulReferrals,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningItem({
    required IconData icon,
    required String title,
    required String value,
    required double scale,
  }) {
    return Row(
      children: [
        Icon(icon, size: 27 * scale, color: const Color(0xFF078B39)),
        SizedBox(width: 7 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 10.5 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: ink,
                  fontSize: 18 * scale,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works?',
          style: TextStyle(
            color: ink,
            fontSize: 17 * scale,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7 * scale),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _step(
              icon: Icons.share_rounded,
              label: '1. Share\nYour Code',
              circleColor: const Color(0xFFE1F1FC),
              iconColor: const Color(0xFF1764B5),
              scale: scale,
            ),
            _arrow(scale),
            _step(
              icon: Icons.directions_car_filled_rounded,
              label: '2. Friend Takes\nTheir First Ride',
              circleColor: const Color(0xFFE1F1FC),
              iconColor: const Color(0xFF1764B5),
              scale: scale,
            ),
            _arrow(scale),
            _step(
              icon: Icons.card_giftcard_rounded,
              label: '3. You Get\n₹100 Reward',
              circleColor: const Color(0xFFF0E8FC),
              iconColor: const Color(0xFF7135C6),
              scale: scale,
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrow(double scale) {
    return Padding(
      padding: EdgeInsets.only(top: 20 * scale),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: ink,
        size: 19 * scale,
      ),
    );
  }

  Widget _step({
    required IconData icon,
    required String label,
    required Color circleColor,
    required Color iconColor,
    required double scale,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 54 * scale,
            height: 54 * scale,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28 * scale),
          ),
          SizedBox(height: 4 * scale),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 10.5 * scale,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditions(double scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10 * scale,
        8 * scale,
        10 * scale,
        8 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF6FF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: navy,
                size: 19 * scale,
              ),
              SizedBox(width: 6 * scale),
              Expanded(
                child: Text(
                  'Referral Rewards & Conditions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _showMessage('Referral terms will be available here'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View Terms',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          _condition(
            'Get ₹100 when your friend completes their first ride (min. ₹199).',
            scale,
          ),
          _condition(
            'Your friend also gets ₹50 OFF on their first ride.',
            scale,
          ),
          _condition(
            'Rewards are added to your Raahi Wallet within 24 hours.',
            scale,
          ),
        ],
      ),
    );
  }

  Widget _condition(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18 * scale,
        top: 2 * scale,
        bottom: 2 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF159B37),
            size: 15 * scale,
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ink,
                fontSize: 10 * scale,
                height: 1.18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitedFriends(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Invited Friends${invitedFriends.isEmpty ? '' : ' (${invitedFriends.length})'}',
                style: TextStyle(
                  color: ink,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _showMessage('Your referral history will appear here'),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(horizontal: 3 * scale),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All  ›',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: line),
          ),
          child: invitedFriends.isEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 9 * scale,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        color: muted,
                        size: 21 * scale,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          'No invited friends available yet.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10.5 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < invitedFriends.length; i++) ...[
                      _friendRow(invitedFriends[i], scale),
                      if (i != invitedFriends.length - 1)
                        Divider(height: 1, color: line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _friendRow(ReferralFriend friend, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 9 * scale,
        vertical: 6 * scale,
      ),
      child: Row(
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: friend.avatarColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              friend.initials,
              style: TextStyle(
                color: friend.initialColor,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Joined on ${friend.joinedDate}',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9.5 * scale,
                  ),
                ),
              ],
            ),
          ),
          if (friend.rewardEarned)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scale,
                vertical: 4 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F9E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF159B37),
                    size: 11 * scale,
                  ),
                  SizedBox(width: 3 * scale),
                  Text(
                    'Reward Earned',
                    style: TextStyle(
                      color: const Color(0xFF16813A),
                      fontSize: 8.5 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(width: 7 * scale),
          Text(
            '+ ₹${friend.rewardAmount}',
            style: TextStyle(
              color: ink,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // The skycity image is used as a real asset, not recreated or replaced.
  // Change skycityAsset above to the exact path in your assets folder.
  Widget _buildBottomAction(double scale) {
    return SizedBox(
      height: 105 * scale,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                skycityAsset,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            left: 14 * scale,
            right: 14 * scale,
            top: 4 * scale,
            child: SizedBox(
              height: 46 * scale,
              child: ElevatedButton.icon(
                onPressed: _shareReferral,
                icon: Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 19 * scale,
                ),
                label: Text(
                  'Share & Invite Friends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReferralFriend {
  final String initials;
  final String name;
  final String joinedDate;
  final bool rewardEarned;
  final int rewardAmount;
  final Color avatarColor;
  final Color initialColor;

  const ReferralFriend({
    required this.initials,
    required this.name,
    required this.joinedDate,
    required this.rewardEarned,
    required this.rewardAmount,
    this.avatarColor = const Color(0xFFEDE4FA),
    this.initialColor = const Color(0xFF6333B5),
  });
}
