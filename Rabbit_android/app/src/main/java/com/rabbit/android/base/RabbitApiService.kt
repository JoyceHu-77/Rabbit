package com.rabbit.android.base

import com.rabbit.android.BuildConfig
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path

interface RabbitApiService {
    @GET("v1/rescues")
    suspend fun fetchRescues(@Header("Authorization") authorization: String): List<RescuePost>

    @POST("v1/rescues")
    suspend fun createRescue(
        @Header("Authorization") authorization: String,
        @Body body: RescueCreateBody,
    ): RescuePost

    @PATCH("v1/rescues/{id}")
    suspend fun updateRescue(
        @Header("Authorization") authorization: String,
        @Path("id") id: String,
        @Body body: RescueCreateBody,
    ): RescuePost

    @GET("v1/donations")
    suspend fun fetchDonations(@Header("Authorization") authorization: String): List<DonationPost>

    @POST("v1/donations")
    suspend fun createDonation(
        @Header("Authorization") authorization: String,
        @Body body: DonationCreateBody,
    ): DonationPost
}

object RabbitApiFactory {
    private val json = Json {
        ignoreUnknownKeys = true
    }

    fun create(): RabbitApiService? {
        val base = BuildConfig.RABBIT_API_BASE_URL.trim().trimEnd('/')
        if (!base.startsWith("http")) return null
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BASIC
        }
        val client = OkHttpClient.Builder()
            .addInterceptor(logging)
            .build()
        return Retrofit.Builder()
            .baseUrl("$base/")
            .client(client)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(RabbitApiService::class.java)
    }
}

fun RescuePost.toCreateBody(): RescueCreateBody = RescueCreateBody(
    id = id,
    title = title,
    description = description,
    images = images,
    location = location,
    city = city,
    district = district,
    date = date,
    status = status,
    finderName = finderName,
    finderContact = finderContact,
    finderIsPublic = finderIsPublic,
    organizerName = organizerName,
    organizerContact = organizerContact,
    organizerIsPublic = organizerIsPublic,
    wechatQR = wechatQR,
    healthStatus = healthStatus,
    sterilizedStatus = sterilizedStatus,
    sourceRabbitId = sourceRabbitId,
    publisherName = publisherName,
    moderationStatus = moderationStatus,
    auditRejectionReason = auditRejectionReason,
)
