#include <fstream>
#include <memory>
#include <opencv2/opencv.hpp>
#include <opencv2/core/utils/logger.hpp>

using namespace std;

const int frameCap = 300;
const cv::Size frameSize(88, 64);
const string filePath = "BadApple.mp4";
const string outputPath = "BadApple.cvid";
const int keyframeFrequency = 999999999;

void Decode(string path)
{
	ifstream vid(path);

	char buf[2];
	vid.read(buf, 2);
	uint16_t frames = (uint16_t)buf[1] << 8 | (uint8_t)buf[0];

	cv::Mat frame(frameSize, CV_8U, 255);
	for (size_t i = 0; i < frames; i++)
	{
		vid.read(buf, 1);
		switch (buf[0])
		{
			//No Change
			case 0:
				break;
			//XOR Frame
			case 1:
				for (int y = 0; y < frameSize.height; y++)
				{
					for (int x = 0; x < frameSize.width; x++)
					{
						vid.read(buf, 1);
						if (buf[0] == 1)
						{
							frame.at<uint8_t>(y, x) = frame.at<uint8_t>(y, x) == 0 ? 255 : 0;
						}
					}
				}
				break;
			//Keyframe
			case 2:
				for (int y = 0; y < frameSize.height; y++)
				{
					for (int x = 0; x < frameSize.width; x++)
					{
						vid.read(buf, 1);
						if (buf[0] == 0)
						{
							frame.at<uint8_t>(y, x) = 255;
						}
						else
						{
							frame.at<uint8_t>(y, x) = 0;
						}
					}
				}
				break;
			//Full black
			case 3:
				frame = 0;
				break;
			//Full white
			case 4:
				frame = 255;
				break;
			default:
				cout << "Invalid frame type\n";
		}

		cv::imshow(path, frame);
		cv::waitKey(5);
	}
}

/*
* FORMAT:
* (2) Num frames
* for num frames:
*   (1) Frame type: 0 = no change, 1 = xor frame, 2 = keyframe, 3 = full black, 4 = full white //TODO: this byte could store the info for 2 frames
*   //TODO: maybe add a frame type for when very few pixels change (<=11), it would then have a list of 2 byte xy coordinates
*	if xor frame:
*		
*/
void Encode(string source, string dest)
{
	cv::VideoCapture vid(source);
	ofstream out(dest, ios::trunc);

	const uint16_t frames = frameCap ? frameCap : vid.get(cv::CAP_PROP_FRAME_COUNT);

	//Write frame count
	out << (uint8_t)frames << (uint8_t)(frames >> 8);

	cv::Mat frame, gray;
	cv::Mat lastFrame(frameSize, CV_8UC1, 255);
	for (size_t i = 0; i < frames; i++)
	{
		vid.read(frame);
		if (frame.empty())
		{
			std::cout << "ERROR! blank frame grabbed\n";
			break;
		}

		cv::Mat res(frameSize, frame.type());
		cv::resize(frame, res, res.size(), 0, 0, cv::INTER_AREA);
		cv::cvtColor(res, gray, cv::COLOR_BGR2GRAY);
		cv::threshold(gray, gray, 128, 255, cv::THRESH_OTSU);

		//Go through each pixel, save it's state and if it has changed
		bool allBlack = true, allWhite = true, anyChanges = false;
		std::vector<uint8_t> frameData, frameDelta;
		frameData.reserve(frameSize.width * frameSize.height);
		frameDelta.reserve(frameSize.width * frameSize.height);
		for (int y = 0; y < frameSize.height; y++)
		{
			for (int x = 0; x < frameSize.width; x++)
			{
				if (gray.at<uint8_t>(y, x) == 0)
				{
					allWhite = false;
					frameData.push_back(1);
				}
				else
				{
					allBlack = false;
					frameData.push_back(0);
				}
				if (gray.at<uint8_t>(y, x) == lastFrame.at<uint8_t>(y, x))
				{
					frameDelta.push_back(0);
				}
				else
				{
					anyChanges = true;
					frameDelta.push_back(1);
				}
			}
		}

		if (!anyChanges)
		{
			//No change
			out << (uint8_t)0;
		}
		else if (allBlack)
		{
			//Full black
			out << (uint8_t)3;
		}
		else if (allWhite)
		{
			//Full white
			out << (uint8_t)4;
		}
		else if (i % keyframeFrequency == 0)
		{
			//Keyframe
			out << (uint8_t)2;
			for (uint8_t pixel: frameData)
			{
				out << pixel;
			}
		}
		else
		{
			//XOR frame
			out << (uint8_t)1;
			for (uint8_t pixel: frameDelta)
			{
				out << pixel;
			}
		}

		lastFrame = gray.clone();

		if (i % 100 == 0)
		{
			cout << "Processed " << i << "/" << frames << " frames" << endl;
		}
	}
	out.close();
}

int main()
{
	cv::utils::logging::setLogLevel(cv::utils::logging::LOG_LEVEL_ERROR);

	Encode(filePath, outputPath);
	Decode(outputPath);

	return 0;
}
