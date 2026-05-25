package ai.buble.sdk.apps;

import java.util.List;

/**
 * Callable preconfigured Buble app workflow.
 */
public class PublicApp {
    private String id;
    private List<AppInputParameter> inputParameters;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public List<AppInputParameter> getInputParameters() { return inputParameters; }
    public void setInputParameters(List<AppInputParameter> inputParameters) { this.inputParameters = inputParameters; }
}
