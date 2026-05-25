package ai.buble.sdk.chat;

import java.util.List;

/**
 * OpenAI-style chat model list.
 */
public class ChatModelList {
    private String object;
    private List<ChatModel> data;

    public String getObject() { return object; }
    public void setObject(String object) { this.object = object; }
    public List<ChatModel> getData() { return data; }
    public void setData(List<ChatModel> data) { this.data = data; }
}
