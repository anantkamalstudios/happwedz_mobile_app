import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/einvite1/weddingCard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ViewAllScreen.dart';

class WeddingInvitesScreen1 extends StatefulWidget {
  const WeddingInvitesScreen1({super.key});

  @override
  State<WeddingInvitesScreen1> createState() => _WeddingInvitesScreen1State();
}

class _WeddingInvitesScreen1State extends State<WeddingInvitesScreen1> {
  final Color pink = const Color(0xFFE91E63);

  List<Map<String, String>> weddingCards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeddingCards();
    fetchWeddingCards().then((_) => _loadDraft());
  }

  Future<void> fetchWeddingCards() async {
    final url = Uri.parse('https://happywedz.com/api/einvites/cards');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<Map<String, String>> fetchedCards = [];
          for (var item in data['data']) {
            // Use backend URL for images
            String imageUrl = item['thumbnailUrl'] ?? '';
            if (imageUrl.contains('happywedz.com')) {
              imageUrl = imageUrl.replaceFirst(
                  'happywedz.com', 'happywedzbackend.happywedz.com');
            }

            fetchedCards.add({
              'title': item['name'] ?? 'Card',
              'image': imageUrl,
              'backgroundUrl': item['backgroundUrl'] ?? '',
            });
          }
          setState(() {
            weddingCards = fetchedCards;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching wedding cards: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    // Save the list of wedding cards as draft
    final draftData = weddingCards
        .map((card) => {
      'title': card['title'],
      'image': card['image'],
      'backgroundUrl': card['backgroundUrl'],
    })
        .toList();

    await prefs.setString('weddingDraft', jsonEncode(draftData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Draft saved successfully!')),
    );
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDraft = prefs.getString('weddingDraft');

    if (savedDraft != null) {
      final List<dynamic> decoded = jsonDecode(savedDraft);
      setState(() {
        weddingCards = decoded
            .map((e) => Map<String, String>.from(e))
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📂 Draft loaded!')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: pink,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.white),
        title: Text(
          "E-Invites",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: "Save Draft",
            onPressed: _saveDraft,
          ),
        ],
      ),


      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Wedding Cards
            _buildSection(
              title: "Wedding Cards",
              cards: weddingCards,
              context: context,
              pink: pink,
            ),
            const SizedBox(height: 20),

            // Video Invites
            _buildSection(
              title: "Video Invites",
              cards: const [],
              context: context,
              pink: pink,
            ),
            const SizedBox(height: 20),

            // Save The Date Cards
            _buildSection(
              title: "Save The Date Cards",
              cards: const [],
              context: context,
              pink: pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, String>> cards,
    required BuildContext context,
    required Color pink,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewAllScreen(
                        categoryTitle: title,
                        cards: cards,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "View all",
                      style: GoogleFonts.poppins(
                        color: pink,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFE91E63),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal scroll
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.isEmpty ? 4 : cards.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      if (title == "Wedding Cards" && cards.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomizeCardScreen(
                              templateImage: cards[index]['image']!,
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 130,
                          width: 95,
                          decoration: cards.isEmpty
                              ? BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          )
                              : null,
                          child: cards.isEmpty
                              ? null
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              cards[index]['image']!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                      Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 95,
                          child: cards.isEmpty
                              ? Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                              : Text(
                            cards[index]['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
