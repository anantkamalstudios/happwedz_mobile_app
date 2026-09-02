const FILTER_CONFIG = {
  photographers: {
    // "no Of Days": ["1 day", "2 days", "3 days", "4 days"],
    // services: ["photo + video", "photo package"],
    prices: [
      "40,000",
      "40,000-80,000",
      "80,000-1,20,000",
      "1,20,000-1,60,000",
      "1,60,000+",
    ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "bridal-makeup": {
    "price (Bridal Makeup)": [
      "12,000",
      "12,000-16,000",
      "16,000-20,000",
      "20,000-25,000",
      "25,000+",
    ],
    "price (Engagement)": ["12,000", "12,000-18,000", "18,000-25,000", "25,000+"],
    // specialty: ["north indian", "south indian", "bengali", "muslim", "marathi"],
    // "travels To Venue": ["travels to venue", "doesn't travel to venue"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  makeup: {
    "price Bridal Makeup": [
      "12,000",
      "12,000-16,000",
      "16,000-20,000",
      "20,000-25,000",
      "25,000+",
    ],
    "price Engagement": ["12,000", "12,000-18,000", "18,000-25,000", "25,000+"],
    // specialty: ["north indian", "south indian", "bengali", "muslim", "marathi"],
    // "travels To Venue": ["travels to venue", "doesn't travel to venue"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "wedding-planners": {
    prices: ["<200,000", "200,000-300,000", "300,000-500,000", "500,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  decorators: {
    "decor Price": [
      "<50,000",
      "50,000-1,00,000",
      "1,00,000-1,50,000",
      "1,50,000-2,50,000",
      "2,50,000-4,00,000",
    ],
    "home Function Decor": [
      "<30,000",
      "30,000-50,000",
      "50,000-75,000",
      "75,000-1,20,000",
      "1,20,000+",
    ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  mehandi: {
    "bridal Price": ["<5,000", "5,000-10,000", "10,000-20,000", "20,000+"],
    "package Price": ["<2,000", "2,000-5,000", "5,001-8,000", "8,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  venues: {
    "venue Type": [
      "Banquet Halls",
      "Marriage Garden / lawns",
      "Wedding Farmhouses",
      "Wedding Resorts",
      "Destination Wedding Venues",
      "Kalyana Mandapams",
      "4 Star And Above Wedding Hotels",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },

  "banquet-halls": {
    "venue Type": [
      "Marriage Garden / lawns",
      "Wedding Farmhouses",
      "Wedding Resorts",
      "Destination Wedding Venues",
      "Kalyana Mandapams",
      "4 Star & Above Wedding Hotels",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1000", "1000-2000", "2000-3000", "3000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },

  "wedding-resorts": {
    "venue Type": [
      "Wedding Resorts",
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Destination Wedding Venues",
      "Kalyana Mandapams",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },

  "destination-wedding-venues": {
    "venue Type": [
      "Destination Wedding Venues",
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },

  "small-functions--party-halls": {
    "venue Type": [
      "small function / party halls",
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
      "Destination Wedding Venues",
      "4 Star & Above Wedding Hotels",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },

  "marriage-garden--lawns": {
    "venue Type": [
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
      "Destination Wedding Venues",
      "Kalyana Mandapams",
      "4 Star & Above Wedding Hotels",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },
  "wedding-farmhouses": {
    "venue Type": [
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
      "Destination Wedding Venues",
      "Kalyana Mandapams",
      "4 Star & Above Wedding Hotels",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },
  "kalyana-mandapams": {
    "venue Type": [
      "Kalyana Mandapams",
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
      "Destination Wedding Venues",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },
  "4-star-and-above-wedding-hotels": {
    "venue Type": [
      "4 Star And Above Wedding Hotels",
      "Wedding Farmhouses",
      "Marriage Garden / lawns",
      "Banquet Halls",
      "Wedding Resorts",
      "Destination Wedding Venues",
    ],
    capacity: ["<100", "100-200", "200-500", "500-1000", "1000+"],
    "price Per Plate": ["<1,000", "1,000-2,000", "2,000-3,000", "3,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    rooms: ["<10", "10-20", "20-30", "30-40", "40-50", "50-100", "100+"],
  },
  catering: {
    // cuisines: [
    //   "north indian",
    //   "south indian",
    //   "chinese",
    //   "continental",
    //   "street food",
    // ],
    "price Per Plate": ["<500", "500-1,000", "1,000-1,500", "1,500+"],
    capacity: ["<100", "100-300", "300-500", "500+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  jewellery: {
    // "jewelry Type": ["bridal set", "necklace", "rings", "bangles", "earrings"],
    "price Range": [
      "<50,000",
      "50,000-1,00,000",
      "1,00,000-2,00,000",
      "2,00,000+",
    ],
    // "rental Available": ["yes", "no"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "wedding-cakes": {
    // flavors: ["chocolate", "vanilla", "red velvet", "fruit", "custom"],
    // tiers: ["1", "2", "3", "4+"],
    "price Range": ["<5,000", "5,000-10,000", "10,000-20,000", "20,000+"],
    // "egg less Available": ["yes", "no"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  invitations: {
    // "invitation Type": ["printed", "digital", "boxed", "customized"],
    "price Range": ["<50", "50-100", "100-200", "200+"],
    // "delivery Time": ["1 week", "2 weeks", "3 weeks+"],
    "physical Invite Price": ["<50", "50-100", "100-200", "200-400", "400+"],
    // "design Cost": ["on request"],
    // speciality: ["boxed invites", "unboxed invites", "digital e-cards"],
    // "min Order Quantity": ["<30", "30-50", "50-100", "100-150", "150+"],
    // "store Type": ["physical store", "online store", "both physical & online"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  groom: {
    // "wear Type": ["sherwani", "suit", "indo-western", "kurta-pajama"],
    "price Range": ["<10,000", "10,000-20,000", "20,000-50,000", "50,000+"],
    // "rental Available": ["yes", "no"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  bridal: {
    // "wear Type": ["lehenga", "saree", "gown", "anarkali"],
    "price Range": ["<20,000", "20,000-50,000", "50,000-1,00,000", "1,00,000+"],
    "rental Available": ["yes", "no"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  bands: {
    // services: ["band", "dhol", "ghori", "baggi", "fireworks"],
    "price Range": ["<20,000", "20,000-50,000", "50,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  choreographers: {
    // "dance Style": ["bollywood", "classical", "hip hop", "contemporary"],
    "package Price": ["<10,000", "10,000-20,000", "20,000-30,000", "30,000+"],
    // "group Size": ["solo", "couple", "group"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  gifts: {
    // "gift Type": [
    //   "return gifts",
    //   "custom gifts",
    //   "luxury gifts",
    //   "edible gifts",
    // ],
    "price Range": ["<500", "500-1,000", "1,000-5,000", "5,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  honeymoon: {
    destinations: ["maldives", "bali", "paris", "switzerland", "kashmir"],
    budget: ["<50,000", "50,000-1,00,000", "1,00,000-2,00,000", "2,00,000+"],
    duration: ["3 days", "5 days", "7 days", "10 days+"],
    rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  djs: {
    "Starting Price": ["<20,000", "20,000-40,000", "40,000-80,000", "80,000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  "sangeet-choreographers": {
    "package Price 10Songs": [
      "<30,000",
      "30,000-50,000",
      "50,000-75,000",
      "75,000+",
    ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  "wedding-entertainment": {
    // events: [
    //   "pre-wedding (roka)",
    //   "wedding",
    //   "sagan",
    //   "cocktail party",
    //   "bachelor/spinster party",
    // ],
    // "travel Preferences": [
    //   "same city",
    //   "domestic",
    //   "international",
    //   "cannot travel",
    // ],
    // type: [
    //   "anchor/emcee",
    //   "live singer",
    //   "live band",
    //   "guest appearance",
    //   "dancers",
    // ],
    price: [
      "<7,500",
      "7,500-12,000",
      "12,000-20,000",
      "20,000-30,000",
      "30,000-50,000",
      "50,000-75,000",
      "75,000+",
    ],
    // experience: ["1-3 years", "3-5 years", "10+ years"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  // favors: {
  //   type: [
  //     "chocolates",
  //     "cookies & biscuits",
  //     "personalized items",
  //     "mithai/sweets",
  //     "flavored tea",
  //   ],
  //   speciality: [
  //     "invitation gifts",
  //     "mehndi favors",
  //     "wedding favors/guest gifting",
  //     "bridesmaids gifts",
  //     "groomsmen gifts",
  //   ],
  //   rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
  //   "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  //   award: ["users' choice awards winner"],
  // },

  "trousseau-packers": {
    // type: [
    //   "baskets for hampers",
    //   "sagan envelopes",
    //   "boxes",
    //   "jaimalas & milni malas",
    //   "saree bags",
    // ],
    // speciality: [
    //   "wedding gift packing",
    //   "fruit basket packing",
    //   "bridal trousseau packing",
    //   "bridesmaids boxes",
    //   "sagan envelopes",
    // ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  "catering-services": {
    "price Per Plate": [
      "<1,000",
      "1,000-1,500",
      "1,500-2,000",
      "2,000-3,000",
      "3,000+",
    ],
    // speciality: [
    //   "full service catering",
    //   "small function catering",
    //   "chaat & fruit stalls",
    //   "food counters",
    //   "paan",
    //   "dessert",
    // ],
    // cuisines: [
    //   "vegetarian only",
    //   "chaat & food stalls",
    //   "north indian/mughlai",
    //   "south indian",
    //   "continental (thai/italian/chinese)",
    // ],
    "max Capacity": ["<100", "100-500", "500-1000", "1000+"],
    "min Capacity": ["<30", "<50", "<70", "<100", "<200"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  cakes: {
    "price Per Kg": ["500-1,000", "1,000-1,500", "1,500-2,500", "2,500-5,000"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  bartenders: {
    type: [
      "general bartenders",
      "flair bartenders",
      "international bartenders",
    ],
    services: [
      "only bartenders",
      "glassware",
      "mixers & garnishes",
      "ice",
      "theme based bar counters",
    ],
    "pricing For 200 Guests": [
      "<10,000",
      "10,000-20,000",
      "20,000-50,000",
      "50,000-1,00,000",
      "1,00,000+",
    ],
    rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "pre-wedding-shoot-location": {
    // "space Available": ["indoor", "outdoor", "indoor with outdoor", "poolside"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "pre-wedding-photographers": {
    // services: ["still photography", "videography", "albums"],
    pricing: ["<10,000", "10,000-25,000", "25,000-50,000", "50,000+"],
    // experience: ["3-5 years", "5-7 years", "7+ years"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "bridal-lehengas": {
    // type: [
    //   "retail shop",
    //   "studio/boutique",
    //   "couture brand",
    //   "multi designer studio",
    //   "rental store",
    // ],
    // "outfit Type": [
    //   "bridal lehengas",
    //   "light lehengas",
    //   "kanjeevaram/silk sarees",
    //   "trousseau sarees",
    //   "bridal lehenga on rent",
    // ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  sherwani: {
    // "outfit Type": [
    //   "wedding suits/tuxes",
    //   "kurta pyjama",
    //   "bandhgala",
    //   "waistcoats/nehru jackets",
    // ],
    // "store Type": [
    //   "studio/boutique",
    //   "retail store",
    //   "couture brand",
    //   "multi designer store",
    // ],
    // accessories: ["safa for groom", "groom pagri", "juttis"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  accessories: {
    // type: [
    //   "shoes",
    //   "clutches & bags",
    //   "bridal kalire",
    //   "bridal chura",
    //   "customised accessories",
    // ],
    "Starting Price": ["500+", "1000+", "1500+", "2000+", "3000+"],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
    // award: ["users' choice awards winner"],
  },

  "wedding-pandits": {
    // languages: ["hindi", "tamil", "telugu", "marathi", "kannada"],
    // experience: ["<1 year", "1-3 years", "3-5 years", "5 years+"],
    // culture: ["hindu", "muslim", "christian"],
    pricing: [
      "<11,000",
      "11,000-21,000",
      "21,000-31,000",
      "31,000-51,000",
      "51,000+",
    ],
    // rating: ["all ratings", "rated <4", "rated 4+", "rated 4.5+", "rated 4.8+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },

  "beauty-wellness": {
    // services: [
    //   "spa",
    //   "skin care",
    //   "hair styling",
    //   "nail art",
    //   "pre-bridal package",
    // ],
    "price Range": ["<5,000", "5,000-10,000", "10,000-20,000", "20,000+"],
    // "review Count": ["<5 reviews", "5+ reviews", "15+ reviews", "30+ reviews"],
  },
};

export const DEFAULT_FILTERS = {
  Price: ["₹10,000 - ₹50,000", "₹50,000 - ₹1,00,000", "₹1,00,000 and more"],
  // Rating: [
  //   "1 Star & above",
  //   "2 Stars & above",
  //   "3 Stars & above",
  //   "4 Stars & above",
  //   "5 Stars",
  // ],
  // Reviews: [
  //   "Under 50 reviews",
  //   "50 - 100 reviews",
  //   "100 - 500 reviews",
  //   "500+ reviews",
  // ],
};

export default FILTER_CONFIG;
