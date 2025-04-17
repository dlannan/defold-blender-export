local ffi = require("ffi")

-- '/Users/davidlannan/Library/Application Support/Blender/2.83/scripts/addons/defender/defoldsync/luajit/darwin/luajit' '/Users/davidlannan/Library/Application Support/Blender/2.83/scripts/addons/sync_tool/defoldsync/main.lua' '/Users/davidlannan/Library/Application Support/Blender/2.83/scripts/addons/defender'

local libs = ffi_luajit_libs or {
   OSX     = { x86 = GDIR_PATH.."/defoldsync/luajit/darwin/libpng16.16.dylib", x64 = GDIR_PATH.."/defoldsync/luajit/darwin/libpng16.16.dylib" },
   Windows = { x64 = "libpng16-16.dll" },
   Linux   = { x64 = "libpng.so", arm = "libpng.so" },
   BSD     = { x86 = "libpng.so",  x64 = "libpng.so" },
   POSIX   = { x86 = "libpng.so",  x64 = "libpng.so" },
   Other   = { x86 = "libpng.so",  x64 = "libpng.so" },
}

--print("PNG LIB: "..tostring(ffi_png_lib).."   "..libs[ ffi.os ][ ffi.arch ])
local png  = ffi.load( ffi_PNG_lib or ffi_png_lib or libs[ ffi.os ][ ffi.arch ]  or "png" )

ffi.cdef[[

typedef unsigned int png_uint_32;
typedef int png_int_32;
typedef unsigned short png_uint_16;
typedef short png_int_16;
typedef unsigned char png_byte;
typedef size_t png_size_t;
typedef png_int_32 png_fixed_point;
typedef void * png_voidp;
typedef png_byte * png_bytep;
typedef png_uint_32 * png_uint_32p;
typedef png_int_32 * png_int_32p;
typedef png_uint_16 * png_uint_16p;
typedef png_int_16 * png_int_16p;
typedef const char * png_const_charp;
typedef char * png_charp;
typedef png_fixed_point * png_fixed_point_p;
typedef void * png_FILE_p;
typedef double * png_doublep;
typedef png_byte * * png_bytepp;
typedef png_uint_32 * * png_uint_32pp;
typedef png_int_32 * * png_int_32pp;
typedef png_uint_16 * * png_uint_16pp;
typedef png_int_16 * * png_int_16pp;
typedef const char * * png_const_charpp;
typedef char * * png_charpp;
typedef png_fixed_point * * png_fixed_point_pp;
typedef double * * png_doublepp;
typedef char * * * png_charppp;
typedef png_size_t png_alloc_size_t;

typedef struct png_color_struct {
   uint8_t red;
   uint8_t green;
   uint8_t blue;
} png_color, *png_colorp, **png_colorpp;

typedef struct png_color_16_struct {
   uint8_t  index;
   uint16_t red;
   uint16_t green;
   uint16_t blue;
   uint16_t gray;
} png_color_16, *png_color_16p, *png_color_16pp;

typedef struct png_color_8_struct
{
   png_byte red;
   png_byte green;
   png_byte blue;
   png_byte gray;
   png_byte alpha;
} png_color_8;
typedef png_color_8 * png_color_8p;
typedef png_color_8 * * png_color_8pp;





typedef struct png_sPLT_entry_struct
{
   png_uint_16 red;
   png_uint_16 green;
   png_uint_16 blue;
   png_uint_16 alpha;
   png_uint_16 frequency;
} png_sPLT_entry;
typedef png_sPLT_entry * png_sPLT_entryp;
typedef png_sPLT_entry * * png_sPLT_entrypp;






typedef struct png_sPLT_struct
{
   png_charp name;
   png_byte depth;
   png_sPLT_entryp entries;
   png_int_32 nentries;
} png_sPLT_t;
typedef png_sPLT_t * png_sPLT_tp;
typedef png_sPLT_t * * png_sPLT_tpp;
typedef struct png_text_struct
{
   int compression;




   png_charp key;
   png_charp text;

   png_size_t text_length;

   png_size_t itxt_length;
   png_charp lang;

   png_charp lang_key;


} png_text;
typedef png_text * png_textp;
typedef png_text * * png_textpp;
typedef struct png_time_struct
{
   png_uint_16 year;
   png_byte month;
   png_byte day;
   png_byte hour;
   png_byte minute;
   png_byte second;
} png_time;
typedef png_time * png_timep;
typedef png_time * * png_timepp;
typedef struct png_unknown_chunk_t
{
    png_byte name[5];
    png_byte *data;
    png_size_t size;


    png_byte location;
}
png_unknown_chunk;
typedef png_unknown_chunk * png_unknown_chunkp;
typedef png_unknown_chunk * * png_unknown_chunkpp;
typedef struct png_info_struct
{

   png_uint_32 width ;
   png_uint_32 height ;
   png_uint_32 valid ;

   png_size_t rowbytes ;

   png_colorp palette ;

   png_uint_16 num_palette ;

   png_uint_16 num_trans ;

   png_byte bit_depth ;

   png_byte color_type ;


   png_byte compression_type ;

   png_byte filter_type ;

   png_byte interlace_type ;



   png_byte channels ;

   png_byte pixel_depth ;
   png_byte spare_byte ;

   png_byte signature[8] ;
   float gamma ;






   png_byte srgb_intent ;
   int num_text ;
   int max_text ;
   png_textp text ;






   png_time mod_time ;
   png_color_8 sig_bit ;
   png_bytep trans_alpha ;

   png_color_16 trans_color ;
   png_color_16 background ;
   png_int_32 x_offset ;
   png_int_32 y_offset ;
   png_byte offset_unit_type ;







   png_uint_32 x_pixels_per_unit ;
   png_uint_32 y_pixels_per_unit ;
   png_byte phys_unit_type ;
   png_uint_16p hist ;
   float x_white ;
   float y_white ;
   float x_red ;
   float y_red ;
   float x_green ;
   float y_green ;
   float x_blue ;
   float y_blue ;

   png_charp pcal_purpose ;
   png_int_32 pcal_X0 ;
   png_int_32 pcal_X1 ;
   png_charp pcal_units ;

   png_charpp pcal_params ;

   png_byte pcal_type ;

   png_byte pcal_nparams ;




   png_uint_32 free_me ;





   png_unknown_chunkp unknown_chunks ;
   png_size_t unknown_chunks_num ;




   png_charp iccp_name ;
   png_charp iccp_profile ;


   png_uint_32 iccp_proflen ;
   png_byte iccp_compression ;




   png_sPLT_tp splt_palettes ;
   png_uint_32 splt_palettes_num ;

   png_byte scal_unit ;

   double scal_pixel_width ;
   double scal_pixel_height ;


   png_charp scal_s_width ;
   png_charp scal_s_height ;







   png_bytepp row_pointers ;



   png_fixed_point int_gamma ;




   png_fixed_point int_x_white ;
   png_fixed_point int_y_white ;
   png_fixed_point int_x_red ;
   png_fixed_point int_y_red ;
   png_fixed_point int_x_green ;
   png_fixed_point int_y_green ;
   png_fixed_point int_x_blue ;
   png_fixed_point int_y_blue ;


} png_info;

typedef png_info * png_infop;
typedef const png_info * png_const_infop;
typedef png_info * * png_infopp;

typedef struct png_row_info_struct
{
   png_uint_32 width;
   png_size_t rowbytes;
   png_byte color_type;
   png_byte bit_depth;
   png_byte channels;
   png_byte pixel_depth;
} png_row_info;

typedef png_row_info * png_row_infop;
typedef png_row_info * * png_row_infopp;







typedef struct png_struct_def png_struct;
typedef png_struct * png_structp;
typedef const png_struct * png_const_structp;

typedef void ( *png_error_ptr) (png_structp, png_const_charp);
typedef void ( *png_rw_ptr) (png_structp, png_bytep, png_size_t);
typedef void ( *png_flush_ptr) (png_structp);
typedef void ( *png_read_status_ptr) (png_structp, png_uint_32, int)
        ;
typedef void ( *png_write_status_ptr) (png_structp, png_uint_32, int)
        ;


typedef void ( *png_progressive_info_ptr) (png_structp, png_infop)
              ;
typedef void ( *png_progressive_end_ptr) (png_structp, png_infop);
typedef void ( *png_progressive_row_ptr) (png_structp, png_bytep, png_uint_32, int)
                     ;




typedef void ( *png_user_transform_ptr) (png_structp, png_row_infop, png_bytep)
                              ;



typedef int ( *png_user_chunk_ptr) (png_structp, png_unknown_chunkp)
                       ;


typedef void ( *png_unknown_chunk_ptr) (png_structp);





typedef void * jmp_buf;
typedef void ( *png_longjmp_ptr) (jmp_buf, int);

typedef png_voidp (*png_malloc_ptr) (png_structp, png_alloc_size_t);
typedef void (*png_free_ptr) (png_structp, png_voidp);

struct png_struct_def
{

   jmp_buf jmpbuf ;
   png_longjmp_ptr longjmp_fn ;


   png_error_ptr error_fn ;

   png_error_ptr warning_fn ;

   png_voidp error_ptr ;

   png_rw_ptr write_data_fn ;

   png_rw_ptr read_data_fn ;

   png_voidp io_ptr ;



   png_user_transform_ptr read_user_transform_fn ;




   png_user_transform_ptr write_user_transform_fn ;







   png_voidp user_transform_ptr ;

   png_byte user_transform_depth ;

   png_byte user_transform_channels ;




   png_uint_32 mode ;

   png_uint_32 flags ;

   png_uint_32 transformations ;


   png_bytep zbuf ;
   png_size_t zbuf_size ;
   int zlib_level ;
   int zlib_method ;
   int zlib_window_bits ;

   int zlib_mem_level ;

   int zlib_strategy ;


   png_uint_32 width ;
   png_uint_32 height ;
   png_uint_32 num_rows ;
   png_uint_32 usr_width ;
   png_size_t rowbytes ;

   png_alloc_size_t user_chunk_malloc_max ;

   png_uint_32 iwidth ;

   png_uint_32 row_number ;
   png_bytep prev_row ;

   png_bytep row_buf ;

   png_bytep sub_row ;

   png_bytep up_row ;

   png_bytep avg_row ;

   png_bytep paeth_row ;

   png_row_info row_info ;


   png_uint_32 idat_size ;
   png_uint_32 crc ;
   png_colorp palette ;
   png_uint_16 num_palette ;

   png_uint_16 num_trans ;
   png_byte chunk_name[5] ;

   png_byte compression ;

   png_byte filter ;
   png_byte interlaced ;

   png_byte pass ;
   png_byte do_filter ;

   png_byte color_type ;
   png_byte bit_depth ;
   png_byte usr_bit_depth ;
   png_byte pixel_depth ;
   png_byte channels ;
   png_byte usr_channels ;
   png_byte sig_bytes ;



   png_uint_16 filler ;




   png_byte background_gamma_type ;

   float background_gamma ;

   png_color_16 background ;


   png_color_16 background_1 ;





   png_flush_ptr output_flush_fn ;

   png_uint_32 flush_dist ;

   png_uint_32 flush_rows ;




   int gamma_shift ;


   float gamma ;
   float screen_gamma ;





   png_bytep gamma_table ;

   png_bytep gamma_from_1 ;
   png_bytep gamma_to_1 ;
   png_uint_16pp gamma_16_table ;

   png_uint_16pp gamma_16_from_1 ;

   png_uint_16pp gamma_16_to_1 ;



   png_color_8 sig_bit ;




   png_color_8 shift ;





   png_bytep trans_alpha ;

   png_color_16 trans_color ;



   png_read_status_ptr read_row_fn ;

   png_write_status_ptr write_row_fn ;


   png_progressive_info_ptr info_fn ;

   png_progressive_row_ptr row_fn ;

   png_progressive_end_ptr end_fn ;

   png_bytep save_buffer_ptr ;

   png_bytep save_buffer ;

   png_bytep current_buffer_ptr ;

   png_bytep current_buffer ;

   png_uint_32 push_length ;

   png_uint_32 skip_length ;

   png_size_t save_buffer_size ;

   png_size_t save_buffer_max ;

   png_size_t buffer_size ;

   png_size_t current_buffer_size ;

   int process_mode ;

   int cur_palette ;



     png_size_t current_text_size ;

     png_size_t current_text_left ;

     png_charp current_text ;

     png_charp current_text_ptr ;

   png_bytep palette_lookup ;
   png_bytep quantize_index ;




   png_uint_16p hist ;



   png_byte heuristic_method ;

   png_byte num_prev_filters ;

   png_bytep prev_filters ;

   png_uint_16p filter_weights ;

   png_uint_16p inv_filter_weights ;

   png_uint_16p filter_costs ;

   png_uint_16p inv_filter_costs ;




   png_charp time_buffer ;




   png_uint_32 free_me ;



   png_voidp user_chunk_ptr ;
   png_user_chunk_ptr read_user_chunk_fn ;




   int num_chunk_list ;
   png_bytep chunk_list ;




   png_byte rgb_to_gray_status ;

   png_uint_16 rgb_to_gray_red_coeff ;
   png_uint_16 rgb_to_gray_green_coeff ;
   png_uint_16 rgb_to_gray_blue_coeff ;







   png_uint_32 mng_features_permitted ;




   png_fixed_point int_gamma ;




   png_byte filter_type ;






   png_voidp mem_ptr ;

   png_malloc_ptr malloc_fn ;

   png_free_ptr free_fn ;




   png_bytep big_row_buf ;




   png_bytep quantize_sort ;
   png_bytep index_to_palette ;


   png_bytep palette_to_index ;





   png_byte compression_type ;


   png_uint_32 user_width_max ;
   png_uint_32 user_height_max ;



   png_uint_32 user_chunk_cache_max ;





   png_unknown_chunk unknown_chunk ;



  png_uint_32 old_big_row_buf_size ;
  png_uint_32 old_prev_row_size ;


  png_charp chunkdata ;



   png_uint_32 io_state ;

};





typedef png_structp version_1_4_9beta01;

typedef png_struct * * png_structpp;

 png_uint_32  png_access_version_number (void);




 void  png_set_sig_bytes (png_structp png_ptr, int num_bytes)
                  ;






 int  png_sig_cmp (png_bytep sig, png_size_t start, png_size_t num_to_check)
                            ;







 png_structp  png_create_read_struct(png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);


 png_structp  png_create_write_struct(png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn);

 png_size_t  png_get_compression_buffer_size
   (png_const_structp png_ptr);

 void  png_set_compression_buffer_size
   (png_structp png_ptr, png_size_t size);

 jmp_buf*  png_set_longjmp_fn
   (png_structp png_ptr, png_longjmp_ptr longjmp_fn, size_t jmp_buf_size);

 int  png_reset_zstream (png_structp png_ptr);




 png_structp  png_create_read_struct_2(png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);
 png_structp  png_create_write_struct_2(png_const_charp user_png_ver, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warn_fn, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);



 void  png_write_sig (png_structp png_ptr);


 void  png_write_chunk (png_structp png_ptr, png_bytep chunk_name, png_bytep data, png_size_t length)
                      ;


 void  png_write_chunk_start (png_structp png_ptr, png_bytep chunk_name, png_uint_32 length)
       ;


 void  png_write_chunk_data (png_structp png_ptr, png_bytep data, png_size_t length)
;


 void  png_write_chunk_end (png_structp png_ptr);


 png_infop  png_create_info_struct(png_structp png_ptr) ;

 void  png_info_init_3 (png_infopp info_ptr, png_size_t png_info_struct_size);


 void  png_write_info_before_PLTE (png_structp png_ptr, png_infop info_ptr);
 void  png_write_info (png_structp png_ptr, png_infop info_ptr);



 void  png_read_info (png_structp png_ptr, png_infop info_ptr);



 png_charp  png_convert_to_rfc1123(png_structp png_ptr, png_timep ptime);




 void  png_convert_from_struct_tm (png_timep ptime, struct tm * ttime);




 void  png_set_expand (png_structp png_ptr);
 void  png_set_expand_gray_1_2_4_to_8 (png_structp png_ptr);
 void  png_set_palette_to_rgb (png_structp png_ptr);
 void  png_set_tRNS_to_alpha (png_structp png_ptr);




 void  png_set_bgr (png_structp png_ptr);




 void  png_set_gray_to_rgb (png_structp png_ptr);





 void  png_set_rgb_to_gray (png_structp png_ptr, int error_action, double red, double green );

 void  png_set_rgb_to_gray_fixed (png_structp png_ptr, int error_action, png_fixed_point red, png_fixed_point green );
 png_byte  png_get_rgb_to_gray_status (png_const_structp png_ptr);


 void  png_build_grayscale_palette (int bit_depth, png_colorp palette);


 void  png_set_strip_alpha (png_structp png_ptr);




 void  png_set_swap_alpha (png_structp png_ptr);




 void  png_set_invert_alpha (png_structp png_ptr);




 void  png_set_filler (png_structp png_ptr, png_uint_32 filler, int flags)
                                  ;




 void  png_set_add_alpha (png_structp png_ptr, png_uint_32 filler, int flags)
                                  ;




 void  png_set_swap (png_structp png_ptr);




 void  png_set_packing (png_structp png_ptr);





 void  png_set_packswap (png_structp png_ptr);




 void  png_set_shift (png_structp png_ptr, png_color_8p true_bits);





 int  png_set_interlace_handling (png_structp png_ptr);




 void  png_set_invert_mono (png_structp png_ptr);





 void  png_set_background (png_structp png_ptr, png_color_16p background_color, int background_gamma_code, int need_expand, double background_gamma);

 void  png_set_strip_16 (png_structp png_ptr);






 void  png_set_quantize (png_structp png_ptr, png_colorp palette, int num_palette, int maximum_colors, png_uint_16p histogram, int full_quantize);







 void  png_set_gamma (png_structp png_ptr, double screen_gamma, double default_file_gamma);






 void  png_set_flush (png_structp png_ptr, int nrows);

 void  png_write_flush (png_structp png_ptr);



 void  png_start_read_image (png_structp png_ptr);


 void  png_read_update_info (png_structp png_ptr, png_infop info_ptr)
                       ;



 void  png_read_rows (png_structp png_ptr, png_bytepp row, png_bytepp display_row, png_uint_32 num_rows);




 void  png_read_row (png_structp png_ptr, png_bytep row, png_bytep display_row);




 void  png_read_image (png_structp png_ptr, png_bytepp image);



 void  png_write_row (png_structp png_ptr, png_bytep row);


 void  png_write_rows (png_structp png_ptr, png_bytepp row, png_uint_32 num_rows);


 void  png_write_image (png_structp png_ptr, png_bytepp image);


 void  png_write_end (png_structp png_ptr, png_infop info_ptr);



 void  png_read_end (png_structp png_ptr, png_infop info_ptr);



 void  png_destroy_info_struct (png_structp png_ptr, png_infopp info_ptr_ptr);


 void  png_destroy_read_struct (void * png_ptr_ptr, png_infopp info_ptr_ptr, png_infopp end_info_ptr_ptr);


 void  png_destroy_write_struct(void *png_ptr_ptr, void *info_ptr_ptr);


 void  png_set_crc_action (png_structp png_ptr, int crit_action, int ancil_action);

 void  png_set_filter (png_structp png_ptr, int method, int filters);

 void  png_set_filter_heuristics (png_structp png_ptr, int heuristic_method, int num_weights, png_doublep filter_weights, png_doublep filter_costs);

 void  png_set_compression_level (png_structp png_ptr, int level);

 void  png_set_compression_mem_level(png_structp png_ptr, int mem_level);

 void  png_set_compression_strategy(png_structp png_ptr, int strategy);

 void  png_set_compression_window_bits(png_structp png_ptr, int window_bits);

 void  png_set_compression_method (png_structp png_ptr, int method);

 void  png_init_io (png_structp png_ptr, png_FILE_p fp);

 void  png_set_error_fn (png_structp png_ptr, png_voidp error_ptr, png_error_ptr error_fn, png_error_ptr warning_fn);


 png_voidp  png_get_error_ptr (png_const_structp png_ptr);

 void  png_set_write_fn (png_structp png_ptr, png_voidp io_ptr, png_rw_ptr write_data_fn, png_flush_ptr output_flush_fn);


 void  png_set_read_fn (png_structp png_ptr, png_voidp io_ptr, png_rw_ptr read_data_fn);


 png_voidp  png_get_io_ptr (png_structp png_ptr);

 void  png_set_read_status_fn (png_structp png_ptr, png_read_status_ptr read_row_fn);

 void  png_set_write_status_fn (png_structp png_ptr, png_write_status_ptr write_row_fn);



 void  png_set_mem_fn (png_structp png_ptr, png_voidp mem_ptr, png_malloc_ptr malloc_fn, png_free_ptr free_fn);

 png_voidp  png_get_mem_ptr (png_const_structp png_ptr);



 void  png_set_read_user_transform_fn (png_structp png_ptr, png_user_transform_ptr read_user_transform_fn);



 void  png_set_write_user_transform_fn (png_structp png_ptr, png_user_transform_ptr write_user_transform_fn);




 void  png_set_user_transform_info (png_structp png_ptr, png_voidp user_transform_ptr, int user_transform_depth, int user_transform_channels);

 png_voidp  png_get_user_transform_ptr   (png_const_structp png_ptr);



 void  png_set_read_user_chunk_fn (png_structp png_ptr, png_voidp user_chunk_ptr, png_user_chunk_ptr read_user_chunk_fn);
 png_voidp  png_get_user_chunk_ptr (png_const_structp png_ptr);






 void  png_set_progressive_read_fn (png_structp png_ptr, png_voidp progressive_ptr, png_progressive_info_ptr info_fn, png_progressive_row_ptr row_fn, png_progressive_end_ptr end_fn);


 png_voidp  png_get_progressive_ptr
   (png_const_structp png_ptr);


 void  png_process_data (png_structp png_ptr, png_infop info_ptr, png_bytep buffer, png_size_t buffer_size);




 void  png_progressive_combine_row (png_structp png_ptr, png_bytep old_row, png_bytep new_row);


 png_voidp  png_malloc (png_structp png_ptr, png_alloc_size_t size);

 png_voidp  png_calloc (png_structp png_ptr, png_alloc_size_t size);


 png_voidp  png_malloc_warn (png_structp png_ptr, png_alloc_size_t size);


 void  png_free (png_structp png_ptr, png_voidp ptr);


 void  png_free_data (png_structp png_ptr, png_infop info_ptr, png_uint_32 free_me, int num);


 void  png_data_freer (png_structp png_ptr, png_infop info_ptr, int freer, png_uint_32 mask);

 png_voidp  png_malloc_default (png_structp png_ptr, png_alloc_size_t size);
 void  png_free_default (png_structp png_ptr, png_voidp ptr);




 void  png_error (png_structp png_ptr, png_const_charp error_message);


 void  png_chunk_error (png_structp png_ptr, png_const_charp error_message);







 void  png_warning (png_structp png_ptr, png_const_charp warning_message);


 void  png_chunk_warning (png_structp png_ptr, png_const_charp warning_message);

 png_uint_32  png_get_valid (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_32 flag);


 png_size_t  png_get_rowbytes (png_const_structp png_ptr, png_const_infop info_ptr);





 png_bytepp  png_get_rows (png_const_structp png_ptr, png_const_infop info_ptr);



 void  png_set_rows (png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers);



 png_byte  png_get_channels (png_const_structp png_ptr, png_const_infop info_ptr);



 png_uint_32  png_get_image_width (png_const_structp png_ptr, png_const_infop info_ptr);


 png_uint_32  png_get_image_height (png_const_structp png_ptr, png_const_infop info_ptr);


 png_byte  png_get_bit_depth (png_const_structp png_ptr, png_const_infop info_ptr);


 png_byte  png_get_color_type (png_const_structp png_ptr, png_const_infop info_ptr);


 png_byte  png_get_filter_type (png_const_structp png_ptr, png_const_infop info_ptr);


 png_byte  png_get_interlace_type (png_const_structp png_ptr, png_const_infop info_ptr);


 png_byte  png_get_compression_type (png_const_structp png_ptr, png_const_infop info_ptr);


 png_uint_32  png_get_pixels_per_meter (png_const_structp png_ptr, png_const_infop info_ptr);
 png_uint_32  png_get_x_pixels_per_meter (png_const_structp png_ptr, png_const_infop info_ptr);
 png_uint_32  png_get_y_pixels_per_meter (png_const_structp png_ptr, png_const_infop info_ptr);



 float  png_get_pixel_aspect_ratio (png_const_structp png_ptr, png_const_infop info_ptr);



 png_int_32  png_get_x_offset_pixels (png_const_structp png_ptr, png_const_infop info_ptr);
 png_int_32  png_get_y_offset_pixels (png_const_structp png_ptr, png_const_infop info_ptr);
 png_int_32  png_get_x_offset_microns (png_const_structp png_ptr, png_const_infop info_ptr);
 png_int_32  png_get_y_offset_microns (png_const_structp png_ptr, png_const_infop info_ptr);




 png_bytep  png_get_signature (png_const_structp png_ptr, png_infop info_ptr);


 png_uint_32  png_get_bKGD (png_const_structp png_ptr, png_infop info_ptr, png_color_16p *background);



 void  png_set_bKGD (png_structp png_ptr, png_infop info_ptr, png_color_16p background);




 png_uint_32  png_get_cHRM (png_const_structp png_ptr, png_const_infop info_ptr, double *white_x, double *white_y, double *red_x, double *red_y, double *green_x, double *green_y, double *blue_x, double *blue_y);


 png_uint_32  png_get_cHRM_fixed (png_const_structp png_ptr, png_const_infop info_ptr, png_fixed_point *int_white_x, png_fixed_point *int_white_y, png_fixed_point *int_red_x, png_fixed_point *int_red_y, png_fixed_point *int_green_x, png_fixed_point *int_green_y, png_fixed_point *int_blue_x, png_fixed_point *int_blue_y);





 void  png_set_cHRM (png_structp png_ptr, png_infop info_ptr, double white_x, double white_y, double red_x, double red_y, double green_x, double green_y, double blue_x, double blue_y);


 void  png_set_cHRM_fixed (png_structp png_ptr, png_infop info_ptr, png_fixed_point int_white_x, png_fixed_point int_white_y, png_fixed_point int_red_x, png_fixed_point int_red_y, png_fixed_point int_green_x, png_fixed_point int_green_y, png_fixed_point int_blue_x, png_fixed_point int_blue_y);





 png_uint_32  png_get_gAMA (png_const_structp png_ptr, png_const_infop info_ptr, double *file_gamma);

 png_uint_32  png_get_gAMA_fixed (png_const_structp png_ptr, png_const_infop info_ptr, png_fixed_point *int_file_gamma);




 void  png_set_gAMA (png_structp png_ptr, png_infop info_ptr, double file_gamma);

 void  png_set_gAMA_fixed (png_structp png_ptr, png_infop info_ptr, png_fixed_point int_file_gamma);



 png_uint_32  png_get_hIST (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_16p *hist);



 void  png_set_hIST (png_structp png_ptr, png_infop info_ptr, png_uint_16p hist);


 png_uint_32  png_get_IHDR (png_structp png_ptr, png_infop info_ptr, png_uint_32 *width, png_uint_32 *height, int *bit_depth, int *color_type, int *interlace_method, int *compression_method, int *filter_method);

 void  png_set_IHDR (png_structp png_ptr, png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth, int color_type, int interlace_method, int compression_method, int filter_method);


 png_uint_32  png_get_oFFs (png_const_structp png_ptr, png_const_infop info_ptr, png_int_32 *offset_x, png_int_32 *offset_y, int *unit_type);



 void  png_set_oFFs (png_structp png_ptr, png_infop info_ptr, png_int_32 offset_x, png_int_32 offset_y, int unit_type);



 png_uint_32  png_get_pCAL (png_const_structp png_ptr, png_const_infop info_ptr, png_charp *purpose, png_int_32 *X0, png_int_32 *X1, int *type, int *nparams, png_charp *units, png_charpp *params);



 void  png_set_pCAL (png_structp png_ptr, png_infop info_ptr, png_charp purpose, png_int_32 X0, png_int_32 X1, int type, int nparams, png_charp units, png_charpp params);



 png_uint_32  png_get_pHYs (png_const_structp png_ptr, png_const_infop info_ptr, png_uint_32 *res_x, png_uint_32 *res_y, int *unit_type);



 void  png_set_pHYs (png_structp png_ptr, png_infop info_ptr, png_uint_32 res_x, png_uint_32 res_y, int unit_type);


 png_uint_32  png_get_PLTE (png_const_structp png_ptr, png_const_infop info_ptr, png_colorp *palette, int *num_palette);

 void  png_set_PLTE (png_structp png_ptr, png_infop info_ptr, png_colorp palette, int num_palette);


 png_uint_32  png_get_sBIT (png_const_structp png_ptr, png_infop info_ptr, png_color_8p *sig_bit);



 void  png_set_sBIT (png_structp png_ptr, png_infop info_ptr, png_color_8p sig_bit);



 png_uint_32  png_get_sRGB (png_const_structp png_ptr, png_const_infop info_ptr, int *intent);



 void  png_set_sRGB (png_structp png_ptr, png_infop info_ptr, int intent);
 void  png_set_sRGB_gAMA_and_cHRM (png_structp png_ptr, png_infop info_ptr, int intent);



 png_uint_32  png_get_iCCP (png_const_structp png_ptr, png_const_infop info_ptr, png_charpp name, int *compression_type, png_charpp profile, png_uint_32 *proflen);




 void  png_set_iCCP (png_structp png_ptr, png_infop info_ptr, png_charp name, int compression_type, png_charp profile, png_uint_32 proflen);




 png_uint_32  png_get_sPLT (png_const_structp png_ptr, png_const_infop info_ptr, png_sPLT_tpp entries);



 void  png_set_sPLT (png_structp png_ptr, png_infop info_ptr, png_sPLT_tp entries, int nentries);




 png_uint_32  png_get_text (png_const_structp png_ptr, png_const_infop info_ptr, png_textp *text_ptr, int *num_text);

 void  png_set_text (png_structp png_ptr, png_infop info_ptr, png_textp text_ptr, int num_text);



 png_uint_32  png_get_tIME (png_const_structp png_ptr, png_infop info_ptr, png_timep *mod_time);



 void  png_set_tIME (png_structp png_ptr, png_infop info_ptr, png_timep mod_time);



 png_uint_32  png_get_tRNS (png_const_structp png_ptr, png_infop info_ptr, png_bytep *trans_alpha, int *num_trans, png_color_16p *trans_color);



 void  png_set_tRNS (png_structp png_ptr, png_infop info_ptr, png_bytep trans_alpha, int num_trans, png_color_16p trans_color);







 png_uint_32  png_get_sCAL (png_const_structp png_ptr, png_const_infop info_ptr, int *unit, double *width, double *height);
 void  png_set_sCAL (png_structp png_ptr, png_infop info_ptr, int unit, double width, double height);
 void  png_set_keep_unknown_chunks (png_structp png_ptr, int keep, png_bytep chunk_list, int num_chunks);
 int  png_handle_as_unknown (png_structp png_ptr, png_bytep chunk_name);


 void  png_set_unknown_chunks (png_structp png_ptr, png_infop info_ptr, png_unknown_chunkp unknowns, int num_unknowns);
 void  png_set_unknown_chunk_location(png_structp png_ptr, png_infop info_ptr, int chunk, int location);
 png_uint_32  png_get_unknown_chunks (png_const_structp png_ptr, png_const_infop info_ptr, png_unknown_chunkpp entries);






 void  png_set_invalid (png_structp png_ptr, png_infop info_ptr, int mask);



 void  png_read_png (png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);
 void  png_write_png (png_structp png_ptr, png_infop info_ptr, int transforms, png_voidp params);


const char* png_get_copyright(       png_const_structp png_ptr );
const char* png_get_header_ver(      png_const_structp png_ptr );
const char* png_get_header_version(  png_const_structp png_ptr );
const char* png_get_libpng_ver(      png_const_structp png_ptr );
uint32_t    png_permit_mng_features( png_structp png_ptr, uint32_t mng_features_permitted );
void        png_set_user_limits(     png_structp png_ptr, png_uint_32 user_width_max, png_uint_32 user_height_max );
uint32_t    png_get_user_width_max(  png_const_structp png_ptr );
uint32_t    png_get_user_height_max( png_const_structp png_ptr );
void        png_set_chunk_cache_max( png_structp png_ptr, uint32_t user_chunk_cache_max);
png_uint_32  png_get_chunk_cache_max(png_const_structp png_ptr);

void  png_set_chunk_malloc_max (png_structp png_ptr, png_alloc_size_t user_chunk_cache_max);
png_alloc_size_t  png_get_chunk_malloc_max(png_const_structp png_ptr);

png_uint_32  png_get_io_state (png_const_structp png_ptr);

png_bytep  png_get_io_chunk_name(png_structp png_ptr);

uint32_t png_get_uint_31(  png_structp png_ptr, void* buf );
uint32_t png_get_uint_32(  png_structp png_ptr, void* buf );
void     png_save_uint_32( void* buf, uint32_t i );
void     png_save_int_32(  void* buf, int32_t  i );
void     png_save_uint_16( void* buf, unsigned i );
]]

local PNG_LIBPNG_VER_STRING   = "1.6.37"
local PNG_TRANSFORM_IDENTITY  = 0x0000  -- /* read and write */

local PNG_COLOR_TYPE_RGB            = 2
local PNG_COLOR_TYPE_RGBA           = 6
local PNG_INTERLACE_NONE            = 0
local PNG_COMPRESSION_TYPE_DEFAULT  = 0
local PNG_FILTER_TYPE_DEFAULT       = 0

local function pngCreate( file_name, w, h, alpha )
   
   local data = nil
   local fp = io.open(file_name, "wb")
   if(fp) then 

      local png_ptr = png.png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
      local info_ptr = png.png_create_info_struct(png_ptr) 

      local bytesize       = 3
      local pixelbyte      = PNG_COLOR_TYPE_RGB
      if(alpha) then 
         bytesize = 4
         pixelbyte = PNG_COLOR_TYPE_RGBA 
      end 

      png.png_set_IHDR(png_ptr, info_ptr, w, h, 8,
             pixelbyte, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT)

      local row_pointers = ffi.cast("uint8_t **", png.png_malloc(png_ptr, h * ffi.sizeof("uint8_t *")))
      for y=0, h-1 do 
         row_pointers[y] = png.png_malloc(png_ptr, w * bytesize) 
         ffi.fill(row_pointers[y],  w * bytesize, 0xFF)
      end 
      png.png_init_io(png_ptr, fp)
      png.png_set_rows(png_ptr, info_ptr, row_pointers)
      png.png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)

      data = {
         png_ptr        = png_ptr,
         info_ptr       = info_ptr,
         row_pointers   = row_pointers,
      }
      png.png_destroy_write_struct(png_ptr, info_ptr)
      fp:close()
   end
   return data
end 

local function pngLoad(file_name)
   local fp = io.open(file_name, "rb")
   local data = nil
   if(fp) then 
      local png_ptr = png.png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
      local info_ptr = png.png_create_info_struct(png_ptr) 
      png.png_init_io(png_ptr, fp)
      png.png_read_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, nil)
      local row_pointers = png.png_get_rows(png_ptr, info_ptr)
      png.png_destroy_read_struct(png_ptr, nil, nil)

      data = {
         png_ptr        = png_ptr,
         info_ptr       = info_ptr,
         row_pointers   = row_pointers,
      }
      fp:close()
   end
   return data 
end 

local function pngSave(file_name, data)

   local fp = io.open(file_name, "wb")
   if(fp) then 
      local png_ptr = png.png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil)
      png.png_init_io(png_ptr, fp)
      png.png_set_rows(png_ptr, data.info_ptr, data.row_pointers)
      png.png_write_png(png_ptr, data.info_ptr, PNG_TRANSFORM_IDENTITY, nil)
      png.png_destroy_write_struct(png_ptr, data.info_ptr)
      fp:close()
   end 
end

local function pngFree( data )

   if(data.info_ptr) then 
      png.png_destroy_info_struct( nil, data.info_ptr )

   end
end

local function test()
   local data = pngLoad("test_in.png")
   pngSave( "test_out.png", data)
end

return 
{
   png      = png, 
   create   = pngCreate,
   load     = pngLoad,
   save     = pngSave,
   free     = pngFree,

   -- test  = test,
}



