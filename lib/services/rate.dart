import 'package:flutter/material.dart';

/// Example usage:
/// Column(
///   children: [
///     /* your SizedBox OutlinedButton here */,
///     const SizedBox(height: 12),
///     RateExperienceCard(),
///   ],
/// )

class RateExperienceCard extends StatefulWidget {
  final void Function(int rating, String comment)? onSubmit;
  const RateExperienceCard({Key? key, this.onSubmit}) : super(key: key);

  @override
  State<RateExperienceCard> createState() => _RateExperienceCardState();
}

class _RateExperienceCardState extends State<RateExperienceCard> {
  int _rating = 0; // 0 means not selected
  final TextEditingController _commentC = TextEditingController();

  static const List<String> _labels = [
    'Select',
    'Very Bad',
    'Needs Improvement',
    'Good',
    'Very Good',
    'Excellent'
  ];

  static const List<IconData> _icons = [
    Icons.sentiment_neutral, // placeholder index 0
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_satisfied,
    Icons.sentiment_satisfied_alt,
    Icons.sentiment_very_satisfied,
  ];

  Color _colorForRating(int rating) {
    if (rating >= 5) return Colors.green.shade600;
    if (rating == 4) return Colors.green.shade400;
    if (rating == 3) return Colors.amber.shade700;
    if (rating == 2) return Colors.deepOrange.shade400;
    if (rating == 1) return Colors.red.shade400;
    return Colors.grey;
  }

  void _handleSubmit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating before submitting.')),
      );
      return;
    }

    final comment = _commentC.text.trim();
    widget.onSubmit?.call(_rating, comment);

    // Example behavior: show a success snackbar and clear
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thanks for your feedback!'),
        backgroundColor: Colors.green.shade600,
      ),
    );

    setState(() {
      _rating = 0;
      _commentC.clear();
    });
  }

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Card(
      color: Colors.pink[50],
      shape: border,
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rate your experience with us',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.pink),
                ),
                // Optional "Skip" or small help text
                TextButton(
                  onPressed: () {
                    // optional skip action
                    setState(() {
                      _rating = 0;
                      _commentC.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback skipped')),
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Skip', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),


            // Stars
            Row(
              children: List.generate(5, (i) {
                final idx = i + 1;
                final isSelected = idx <= _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _colorForRating(_rating).withOpacity(0.12) : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.star,
                      size: 28,
                      color: isSelected ? _colorForRating(_rating) : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),



            // Sentiment / label
            Row(
              children: [
                Icon(
                  _icons[_rating.clamp(0, 5)],
                  size: 22,
                  color: _colorForRating(_rating),
                ),
                const SizedBox(width: 8),
                Text(
                  _labels[_rating.clamp(0, 5)],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _rating > 0 ? _colorForRating(_rating) : Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Optional comment field
            TextField(
              controller: _commentC,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a short note (optional)',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Buttons: Submit (primary) + maybe "Later" small
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleSubmit,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child:  Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.pink[100]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      _rating = 5;
                    });
                    _handleSubmit();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.pink.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
