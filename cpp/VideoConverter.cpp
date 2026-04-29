#include <fstream>
#include <opencv2/opencv.hpp>

using namespace std;

const int frameCap = 300;
const cv::Size frameSize(88, 64);
const string filePath = "BadApple.mp4";
const string outputPath = "BadApple.cvid";
const int keyframeFrequency = 99999999999999;

void Decode(string path)
{
	ifstream vid(path);

	char buf[2];
	vid.read(buf, 2);
	uint16_t frames = (uint16_t)buf[1] << 8 | (uint8_t)(buf[0]);

	cv::Mat frame(frameSize, CV_8U);
	for (size_t i = 0; i < frames; i++)
	{
		vid.read(buf, 1);
		if (buf[0] == 1)
		{
			//XOR Frame
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
		}
		else
		{
			//Keyframe
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
		}

		cv::imshow(path, frame);
		cv::waitKey(5);
	}
}

/*
* FORMAT:
* (2) Num frames
* for num frames:
*   (1) Frame type: 0 = no change, 1 = rle xor frame, 2 = rle keyframe, 3 = full black, 4 = full white
*	if rle xor frame:
*		
*/
void Encode(string source, string dest)
{
	cv::VideoCapture vid(source);
	ofstream out(dest, ios::trunc);

	const uint16_t frames = frameCap ? frameCap : vid.get(cv::CAP_PROP_FRAME_COUNT);

	//Write frame count
	out << (uint8_t)frames << (uint8_t)(frames >> 8);

	cv::Mat lastFrame, frame, gray;
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

		if (i % keyframeFrequency == 0)
		{
			//Keyframe
			out << (uint8_t)2;

			for (int y = 0; y < frameSize.height; y++)
			{
				for (int x = 0; x < frameSize.width; x++)
				{
					if (gray.at<uint8_t>(y, x) > 255 / 2)
					{
						out << (uint8_t)0;
					}
					else
					{
						out << (uint8_t)1;
					}
				}
			}
		}
		else
		{
			//XOR frame
			out << (uint8_t)1;

			int inarow = 0;
			for (int y = 0; y < frameSize.height; y++)
			{
				for (int x = 0; x < frameSize.width; x++)
				{
					if (gray.at<uint8_t>(y, x) == lastFrame.at<uint8_t>(y, x))
					{
						out << (uint8_t)0;
						inarow++;
					}
					else
					{
						if (inarow > 127)
						{
							cout << inarow << endl;
						}
						inarow = 0;
						out << (uint8_t)1;
					}
				}
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
