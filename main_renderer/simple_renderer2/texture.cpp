#include "texture.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb/stb_image_write.h"

#define TINYEXR_IMPLEMENTATION
#include "tinyexr/tinyexr.h"

Texture::Texture(std::string pathToImage)
{
    size_t pos = pathToImage.find(".exr");

    if (pos > pathToImage.length()) {
        this->type = TextureType::UNSIGNED_INTEGER_ALPHA;
        pos = pathToImage.find(".png");

        if (pos > pathToImage.length()) 
            this->loadJpg(pathToImage);
        else
            this->loadPng(pathToImage);
    }
    else {
        this->type = TextureType::FLOAT_ALPHA;
        this->loadExr(pathToImage);
    }
}

void Texture::allocate(TextureType type, Vector2i resolution)
{
    this->resolution = resolution;
    this->type = type;

    if (this->type == TextureType::UNSIGNED_INTEGER_ALPHA) {
        uint32_t* dpointer = (uint32_t*) malloc(this->resolution.x * this->resolution.y * sizeof(uint32_t));
        this->data = (uint64_t)dpointer;
    }
    else if (this->type == TextureType::FLOAT_ALPHA) {
        float* dpointer = (float*)malloc(this->resolution.x * this->resolution.y * 4 * sizeof(float));
        this->data = (uint64_t)dpointer;
    }
}

void Texture::writePixelColor(Vector3f color, int x, int y)
{
    if (this->type == TextureType::UNSIGNED_INTEGER_ALPHA) {
        uint32_t* dpointer = (uint32_t*)this->data;

        uint32_t r = static_cast<uint32_t>(std::min(color.x * 255.0f, 255.f));
        uint32_t g = static_cast<uint32_t>(std::min(color.y * 255.0f, 255.f)) << 8;
        uint32_t b = static_cast<uint32_t>(std::min(color.z * 255.0f, 255.f)) << 16;
        uint32_t a = 255 << 24;

        uint32_t final = r | g | b | a;

        dpointer[y * this->resolution.x + x] = final;
    }
}


Vector3d Texture::nearestNeighbourFetch(double x,double y){//x,y
    // rounf of double 
    double roundedNumberx = round(x);//round returns double
    int roundedIntx = static_cast<int>(roundedNumberx);//tupecast double to int

    double roundedNumbery = round(y);
    int roundedInty = static_cast<int>(roundedNumbery);

    return loadPixelColor(roundedIntx,roundedInty);
    // fetch pixel of this rounded u,v using loadpixel
}
Vector3d Texture::bilinearFetch(double ux,double uy){//ux*res,uy,res

    int ymin=floor(uy);    int xmin=floor(ux);//tested
    int ymax=ceil(uy);     int xmax=ceil(ux);

    uv_cor P1(xmin,ymax);//struct coorrect
    uv_cor P2(xmax,ymax);
    uv_cor P3(xmin,ymin);//have integer stored
    uv_cor P4(xmax,ymin);

    P1.C = loadPixelColor(P1.P.x,P1.P.y);
    P2.C = loadPixelColor(P2.P.x,P2.P.y);
    P3.C = loadPixelColor(P3.P.x,P3.P.y);
    P4.C = loadPixelColor(P4.P.x,P4.P.y);

    Vector3d Cu = (P2.P.x - ux)* P1.C   +   (ux - P1.P.x)* P2.C;

    Vector3d Cl = (P4.P.x - ux)* P3.C   +   (ux - P3.P.x)* P4.C;

    Vector3d Color= abs(P3.P.y - uy)*Cu   +  abs(uy - P1.P.y) *Cl  ; 



    // find square coordinate tl,tr,bl,br which will be int
    // find their uv 
    // interpolate bilinear
    //     =>(find point's uv ,loadpixel)
     return Color;
    
}

/*
Reads the color defined at integer coordinates 'x,y'.
The top left corner of the texture is mapped to '0,0'.
*/
Vector3d Texture::loadPixelColor(int x, int y) {

    // if(x>this->resolution.x ){ std::cout<<"yes\n";  x=this->resolution.x;  }
    // if(y>this->resolution.y ){  std::cout<<"yes\n"; y=this->resolution.y;  }
    
    Vector3d rval(0.f, 0.f, 0.f);
    if (this->type == TextureType::UNSIGNED_INTEGER_ALPHA) {
        uint32_t* dpointer = (uint32_t*)this->data;

        uint32_t val = dpointer[y * this->resolution.x + x];
        uint32_t r = (val >> 0) & 255u;
        uint32_t g = (val >> 8) & 255u;
        uint32_t b = (val >> 16) & 255u;

        rval.x = r / 255.f;
        rval.y = g / 255.f;
        rval.z = b / 255.f;

        // if(r!=g)
            // std::cout<<" rgb    "<<rval.x<<" "<<rval.y<<" "<<rval.z<<std::endl;
    }

    return rval;
}

void Texture::loadJpg(std::string pathToJpg)
{
    Vector2i res;
    int comp;
    unsigned char* image = stbi_load(pathToJpg.c_str(), &res.x, &res.y, &comp, STBI_rgb_alpha);
    int textureID = -1;
    if (image) {
        this->resolution = res;
        this->data = (uint64_t)image;

        /* iw - actually, it seems that stbi loads the pictures
            mirrored along the y axis - mirror them here */
        for (int y = 0; y < res.y / 2; y++) {
            uint32_t* line_y = (uint32_t*)this->data + y * res.x;
            uint32_t* mirrored_y = (uint32_t*)this->data + (res.y - 1 - y) * res.x;
            int mirror_y = res.y - 1 - y;
            for (int x = 0; x < res.x; x++) {
                std::swap(line_y[x], mirrored_y[x]);
            }
        }
    }
    else {
        std::cerr << "Could not load .jpg texture from " << pathToJpg << std::endl;
        std::cerr << stbi_failure_reason() << std::endl;
        exit(1);
    }
}

void Texture::loadPng(std::string pathToPng)
{
    Vector2i res;
    int comp;
    unsigned char* image = stbi_load(pathToPng.c_str(), &res.x, &res.y, &comp, STBI_rgb_alpha);
    int textureID = -1;
    if (image) {
        this->resolution = res;
        this->data = (uint64_t)image;

        /* iw - actually, it seems that stbi loads the pictures
            mirrored along the y axis - mirror them here */
        for (int y = 0; y < res.y / 2; y++) {
            uint32_t* line_y = (uint32_t*)this->data + y * res.x;
            uint32_t* mirrored_y = (uint32_t*)this->data + (res.y - 1 - y) * res.x;
            int mirror_y = res.y - 1 - y;
            for (int x = 0; x < res.x; x++) {
                std::swap(line_y[x], mirrored_y[x]);
            }
        }
    }
    else {
        std::cerr << "Could not load .png texture from " << pathToPng << std::endl;
        std::cerr << stbi_failure_reason() << std::endl;
        exit(1);
    }
}

void Texture::loadExr(std::string pathToExr)
{
    int width;
    int height;
    const char* err = nullptr; // or nullptr in C++11
    
    float* data;
    int ret = LoadEXR(&data, &width, &height, pathToExr.c_str(), &err);
    this->data = (uint64_t)data;

    if (ret != TINYEXR_SUCCESS) {
        std::cerr << "Could not load .exr texture map from " << pathToExr << std::endl;
        exit(1);
    }
    else {
        this->resolution = Vector2i(width, height);
    }
}

void Texture::save(std::string path)
{
    size_t pos = path.find(".png");

    if (pos > path.length()) {
        this->saveExr(path);
    }
    else {
        this->savePng(path);
    }
}

void Texture::saveExr(std::string path)
{
    if (this->type == TextureType::FLOAT_ALPHA) {
        uint64_t hostData = this->data;

        const char* err = nullptr;
        SaveEXR((float*)hostData, this->resolution.x, this->resolution.y, 4, 0, path.c_str(), &err);
        
        if (err == nullptr)
            std::cout << "Saved EXR: " << path << std::endl;
        else
            std::cerr << "Could not save EXR: " << err << std::endl;
    }
    else {
        std::cerr << "Cannot save to EXR: texture is not of type float." << std::endl;
    }
}

void Texture::savePng(std::string path) 
{
    if (this->type == TextureType::UNSIGNED_INTEGER_ALPHA) {
        uint64_t hostData = this->data;
        const uint32_t* data = (const uint32_t*)hostData;

        std::vector<uint32_t> pixels;
        for (int y = 0; y < this->resolution.y; y++) {
            const uint32_t* line = data + (this->resolution.y - 1 - y) * this->resolution.x;
            for (int x = 0; x < this->resolution.x; x++) {
                pixels.push_back(line[x] | (0xff << 24));
            }
        }

        stbi_write_png(path.c_str(), this->resolution.x, this->resolution.y, 4, data, this->resolution.x * sizeof(uint32_t));

        std::cout << "Saved PNG: " << path << std::endl;
    }
    else {
        std::cerr << "Cannot save to PNG: texture is not of type uint32." << std::endl;
    }
}