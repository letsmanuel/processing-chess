import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

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
          return saveAtomically(fileKey, values);
        }
      }
    }

    values.append(construct);
    return saveAtomically(fileKey, values);
  }

  boolean saveAtomically(String fileKey, JSONArray values) {
    Path temporaryFile = null;

    try {
      Path target = saveFile("data/savefile/" + fileKey + ".json").toPath();
      temporaryFile = Files.createTempFile(target.getParent(), target.getFileName().toString(), ".tmp");
      Files.writeString(temporaryFile, values.format(2));
      Files.move(temporaryFile, target, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
      return true;
    }
    catch (IOException e) {
      e.printStackTrace();
      return false;
    }
    finally {
      if (temporaryFile != null) {
        try {
          Files.deleteIfExists(temporaryFile);
        }
        catch (IOException e) {
          e.printStackTrace();
        }
      }
    }
  }
}
