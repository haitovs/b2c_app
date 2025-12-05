class TourismService {
  // Mock data for now
  Future<List<dynamic>> getAgenda(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        "id": 1,
        "title": "The China–Turkmenistan Cooperation Forum",
        "date": "2025-05-21",
        "start_time": "10:00",
        "end_time": "11:00",
        "location": "Central Hall",
        "description":
            "The China–Turkmenistan Cooperation Forum was held in Ashgabat to strengthen bilateral relations and expand economic, cultural, and technological cooperation between the two countries. The event brought together government officials, business representatives, and experts from both China and Turkmenistan. During the forum, both sides discussed key areas of partnership, including energy, infrastructure development, agriculture, and education. Special attention was given to the joint projects in natural gas export and transportation, as Turkmenistan is one of the main energy partners of China in Central Asia.",
        "moderator": {
          "name": "Sebastian Archibald Montgomery",
          "title": "Chief Communication Officer at Nova Culture Institute",
          "image": "assets/moderator.jpg", // Placeholder
        },
        "speakers": [
          {"name": "Speaker 1", "title": "Title 1"},
          {"name": "Speaker 2", "title": "Title 2"},
        ],
        "sponsor": {"name": "Gold Sponsor", "logo": "assets/sponsor.png"},
      },
      {
        "id": 2,
        "title": "Lunch in the banquet hall “Gulzaman”",
        "date": "2025-05-21",
        "start_time": "13:00",
        "end_time": "14:00",
        "location": "Banquet Hall",
        "description": "Networking lunch for all participants.",
        "sponsor": {"name": "Gold Sponsor", "logo": "assets/sponsor.png"},
      },
    ];
  }
}
