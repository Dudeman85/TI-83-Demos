#include <cmath>
#include <cstdint>
#include <fstream>
#include <vector>

int main()
{
    using namespace std;
    ofstream file("var.8xv", ios::trunc);

    //Size of the actual variable
    uint16_t varSize = 768;
    //Size of the data section, +17 for var entry header, +2 for var header (List)
    uint16_t dataSize = varSize + 17 + 2;
    string varName = "VID1";
    varName.resize(8, 0x0);
    string comment = "AppVar test comment!";
    comment.resize(42, 0x0);

    //Write the header for appvar
    //https://merthsoft.com/linkguide/ti83+/fformat.html
    file << "**TI83F*";
    file << (uint8_t)0x1A << (uint8_t)0x0A << (uint8_t)0x0;
    for (int i = 0; i < 42; i++)
    {
        file << (uint8_t)comment[i];
    }
    file << (uint8_t)(dataSize) << (uint8_t)(dataSize>>8); //for var entry header

    //Make the data section
    //Store in vector for checksum calcs
    std::vector<uint8_t> data;
    data.reserve(dataSize);

    //Var entry header
    data.push_back(0xD);
    data.push_back(0x0);
    data.push_back(varSize + 2);
    data.push_back((varSize + 2) >> 8);
    data.push_back(0x15); //AppVar ID
    for (int i = 0; i < 8; i++)
    {
        data.push_back(varName[i]);
    }
    data.push_back(0x0);
    data.push_back(0x80);
    data.push_back(varSize + 2);
    data.push_back((varSize + 2) >> 8);

    //Make the Variable Data
    data.push_back(varSize);
    data.push_back(varSize >> 8);
    for (int i = 0; i < varSize; i++)
    {
        if ((i / 12) % 2 == 0)
        {
            data.push_back(0b10101010);
        }
        else
        {
            data.push_back(0b01010101);
        }
    }

    //Make the checksum
    uint16_t sum = 0;
    for (uint8_t c: data)
    {
        file << c;
        sum += c;
    }
    file << (uint8_t)(sum) << (uint8_t)(sum >> 8);

    file.close();
    return 0;
}
