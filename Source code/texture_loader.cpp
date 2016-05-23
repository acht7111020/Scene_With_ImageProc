#include "texture_loader.h"
#include <cstdio>
#include <jpeg/jpeglib.h>
#include <png/png.h>
#include <cstring>

texture_data load_png(const char* path)
{
    texture_data texture;

    // libpng calls
    png_image image;
    memset(&image, 0, sizeof(png_image));
    image.version = PNG_IMAGE_VERSION;
	png_image_begin_read_from_file(&image, path);
    image.format = PNG_FORMAT_RGBA;
    unsigned char* data = new unsigned char[PNG_IMAGE_SIZE(image)];
    png_image_finish_read(&image, NULL, data, 0, NULL);

    // mirror the image horizontally
    for (size_t i = 0; i < image.width; i++) {
        for (size_t j = 0; j < image.height / 2; j++) {
			for(size_t k = 0; k < 4; k++) {
				size_t idx1 = (j * image.width + i) * 4 + k;
				size_t idx2 = ((image.height - j - 1) * image.width + i) * 4 + k;
				unsigned char temp = data[idx1];
				data[idx1] = data[idx2];
				data[idx2] = temp;
			}
        }
    }

    texture.width = image.width;
    texture.height = image.height;
	texture.data = data;
    return texture;
}

texture_data load_jpg(const char* path)
{
    texture_data texture;

	FILE* jpeg = fopen(path, "rb");

    if (jpeg == 0) {
        return texture;
    }

	struct jpeg_decompress_struct cinfo;
    struct jpeg_error_mgr jerr;
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, jpeg);
    jpeg_read_header(&cinfo, true);
    jpeg_start_decompress(&cinfo);

	// mirror the image horizontally
    unsigned char* data = new unsigned char[cinfo.output_width * cinfo.output_height * cinfo.output_components];
	unsigned char* ptr = data + (cinfo.output_width * cinfo.output_height * cinfo.output_components);
    while(cinfo.output_scanline < cinfo.output_height) {
		ptr -= cinfo.output_width * cinfo.output_components;
        jpeg_read_scanlines( &cinfo, &ptr, 1 );
    }

	texture.width = cinfo.output_width;
	texture.height = cinfo.output_height;
	texture.data = data;

    // clean up and return
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
	fclose(jpeg);
    return texture;
}

void free_texture_data(texture_data data)
{
	delete data.data;
	data.data = 0;
	data.width = data.height = 0;
}