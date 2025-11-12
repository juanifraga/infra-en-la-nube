const {
  CodeBuildClient,
  StartBuildCommand,
} = require("@aws-sdk/client-codebuild");

const codebuild = new CodeBuildClient({});

const CODEBUILD_PROJECT = process.env.CODEBUILD_PROJECT;

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  try {
    const s3Event = event.Records[0].s3;
    const key = decodeURIComponent(s3Event.object.key.replace(/\+/g, " "));

    console.log(`New markdown file detected: ${key}`);
    console.log(`Triggering CodeBuild project: ${CODEBUILD_PROJECT}`);

    const command = new StartBuildCommand({
      projectName: CODEBUILD_PROJECT,
      sourceVersion: process.env.GITHUB_BRANCH || "main",
    });

    const response = await codebuild.send(command);

    console.log(
      `CodeBuild started successfully. Build ID: ${response.build.id}`
    );

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Docusaurus rebuild triggered successfully",
        file: key,
        buildId: response.build.id,
        buildStatus: response.build.buildStatus,
      }),
    };
  } catch (error) {
    console.error("Error:", error);
    throw error;
  }
};
