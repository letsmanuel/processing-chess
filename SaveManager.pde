class SaveManager {


  void init() {
  }

  String load(String fileKey, String callKey) {
    JSONArray values = loadJSONArray("data/savefile/" + fileKey + ".json");

    if (values == null) {
      return null;
    }

    for (int i = 0; i < values.size(); i++) {
      JSONObject entry = values.getJSONObject(i);

      if (entry != null && callKey.equals(entry.getString("id"))) {
        return entry.getString("value");
      }
    }

    return null;
  }


  boolean save(String fileKey, String saveCallkey, String saveCallValue, boolean overwriteIfExists) {
    JSONArray values = loadJSONArray("data/savefile/" + fileKey + ".json");

    if (values == null) {
      values = new JSONArray();
    }

    JSONObject construct = new JSONObject();
    construct.setString("id", saveCallkey);
    construct.setString("value", saveCallValue);

    if (overwriteIfExists) {
      for (int i = 0; i < values.size(); i++) {
        JSONObject entry = values.getJSONObject(i);

        if (entry != null && saveCallkey.equals(entry.getString("id"))) {
          values.setJSONObject(i, construct);
          saveJSONArray(values, "data/savefile/" + fileKey + ".json");
          return true;
        }
      }
    }

    values.append(construct);
    saveJSONArray(values, "data/savefile/" + fileKey + ".json");

    return true;
  }
}
