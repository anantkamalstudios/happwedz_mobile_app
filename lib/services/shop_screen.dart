import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  final List<Map<String, String>> categories = [
    {"name": "Dresses", "icon": "assets/images/wed_dress.jpg"},
    {"name": "Jewellery", "icon": "assets/images/jewellery.jpg"},
    {"name": "Decor", "icon": "assets/images/decor1.jpg"},
    {"name": "Gifts", "icon": "assets/images/gift.jpg"},
  ];

  final List<Map<String, String>> products = [
    {
      "name": "Bridal Lehenga",
      "price": "₹49,999",
      "image": "assets/images/bridal_lehenga.jpg"
    },
    {
      "name": "Diamond Necklace",
      "price": "₹1,20,000",
      "image": "assets/images/diamond_necklace.jpg"
    },
    {
      "name": "Wedding Stage Decor",
      "price": "₹15,000",
      "image": "assets/images/wed_stage_decor.jpg"
    },
    {
      "name": "Wedding Gifts",
      "price": "₹5,000",
      "image": "assets/images/gift.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Top banner with gradient and search
          SliverAppBar(
          expandedHeight: 80,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[100]!, Colors.pink[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search for items...",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.camera_alt_outlined,
                                  color: Colors.grey),
                              onPressed: () {
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.shopping_cart,
                                  color: Colors.grey),
                              onPressed: () {
                                // Camera click logic here
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Shop by Category",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.pink)),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Image.asset(categories[index]["icon"]!,),
                            ),
                            SizedBox(height: 5),
                            Text(categories[index]["name"]!,
                                style: TextStyle(fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product grid
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.asset(
                            products[index]["image"]!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Text(
                            products[index]["name"]!,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            products[index]["price"]!,
                            style: TextStyle(
                              color: Colors.pink[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink[100],
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: products[index],
                                      ),
                                    ),
                                  );
                                },
                                child: Text("View"),
                              ),

                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.pink[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.shopping_cart_outlined, color: Colors.pink),
                                onPressed: () {



                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
                childCount: products.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
            ),
          )
        ],
      ),
    );
  }
}









class ProductDetailsScreen extends StatelessWidget {
  final Map<String, String> product;

  const ProductDetailsScreen({super.key, required this.product});

  // Function to launch WhatsApp
  // void _openWhatsApp(String phone) async {
  //   final Uri url = Uri.parse("https://wa.me/$phone?text=Hello, I'm interested in ${product["name"]}");
  //   if (await canLaunchUrl(url)) {
  //     await launchUrl(url, mode: LaunchMode.externalApplication);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product["name"] ?? ""),
        backgroundColor: Colors.pink[100],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.asset(
                product["image"]!,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product["name"] ?? "",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),

                  // Company Name
                  Text(
                    product["company"] ?? "Company Name",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    product["price"] ?? "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Product Description
                  const Text(
                    "Product Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product["description"] ??
                        "This is a detailed description of the product. "
                            "Add material info, size guide, delivery details, and customization options here.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),

                  const SizedBox(height: 20),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Add to cart logic
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}








